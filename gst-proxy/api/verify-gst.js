const fetch = require("node-fetch");

// Only allow requests from our Firebase Hosting domain (and localhost for local dev)
const ALLOWED_ORIGINS = [
  "https://billings-app-77b3e.web.app",
  "https://billings-app-77b3e.firebaseapp.com",
  "http://localhost",
  "http://localhost:8080",
  "http://localhost:5000",
];

function isOriginAllowed(origin) {
  if (!origin) return false;
  return ALLOWED_ORIGINS.some((allowed) => origin.startsWith(allowed));
}

/**
 * Vercel Serverless Function: /api/verify-gst
 *
 * Acts as a secure proxy for the sandbox.co.in GST verification API.
 * The API keys are stored as Vercel environment variables (never exposed to client).
 *
 * POST /api/verify-gst
 * Body: { "gstin": "27AAPFU1234A1Z5" }
 * Response: { success, name, address, city, state, pincode }
 */
module.exports = async function handler(req, res) {
  const origin = req.headers["origin"] || "";

  // Block requests from unknown origins
  if (!isOriginAllowed(origin)) {
    return res.status(403).json({ error: "Forbidden: origin not allowed." });
  }

  // Set CORS headers — only echo back the allowed origin, not *
  res.setHeader("Access-Control-Allow-Origin", origin);
  res.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");

  // Handle CORS preflight request
  if (req.method === "OPTIONS") {
    return res.status(200).end();
  }

  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  const { gstin } = req.body ?? {};

  if (!gstin || typeof gstin !== "string" || gstin.length !== 15) {
    return res.status(400).json({ error: "A valid 15-digit GSTIN is required." });
  }

  const apiKey = process.env.X_API_KEY;
  const apiSecret = process.env.X_API_SECRET;

  if (!apiKey || !apiSecret) {
    return res.status(500).json({ error: "API keys are not configured on the server." });
  }

  try {
    // Step 1: Authenticate with sandbox.co.in
    const authResponse = await fetch("https://api.sandbox.co.in/authenticate", {
      method: "POST",
      headers: {
        "x-api-key": apiKey,
        "x-api-secret": apiSecret,
      },
    });

    if (!authResponse.ok) {
      const body = await authResponse.text();
      console.error("Auth failed:", body);
      return res.status(502).json({ error: "Authentication with GST API failed." });
    }

    const authData = await authResponse.json();
    const accessToken = authData?.data?.access_token;

    if (!accessToken) {
      return res.status(502).json({ error: "Could not retrieve access token." });
    }

    // Step 2: Fetch GST details
    const gstResponse = await fetch(
      "https://api.sandbox.co.in/gst/compliance/public/gstin/search",
      {
        method: "POST",
        headers: {
          Authorization: accessToken,
          "Content-Type": "application/json",
          "x-accept-cache": "false",
          "x-api-key": apiKey,
          "x-api-version": "1.0.0",
        },
        body: JSON.stringify({ gstin }),
      }
    );

    const gstData = await gstResponse.json();

    if (gstResponse.ok && gstData?.code === 200) {
      const data = gstData?.data?.data ?? {};
      const businessName = data.tradeNam || data.lgnm || "";
      const addressObj = data.pradr?.addr ?? {};

      // Build full address from parts:
      // flno (Floor/Flat) → bno (Building No) → bnm (Building Name) → st (Street) → loc (Locality)
      const addressParts = [
        addressObj.flno,  // Floor / Flat number
        addressObj.bno,   // Building number
        addressObj.bnm,   // Building name
        addressObj.st,    // Street
        addressObj.loc,   // Locality
      ].filter((part) => part && part.trim() !== "");

      const fullAddress = addressParts.join(", ");

      return res.status(200).json({
        success: true,
        name: businessName,
        address: fullAddress,
        city: addressObj.dst || "",      // District / City
        state: addressObj.stcd || "",    // State code name
        pincode: addressObj.pncd || "",  // Pincode
        phone: "",
        email: "",
      });
    } else {
      return res.status(404).json({
        success: false,
        error: gstData?.message ?? "Could not find GST details for this number.",
      });
    }
  } catch (e) {
    console.error("Unexpected error:", e);
    return res.status(500).json({ error: "An unexpected error occurred." });
  }
};
