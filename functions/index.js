const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const fetch = require("node-fetch");

// Deploy functions to a region closer to India
setGlobalOptions({ region: "asia-south1" });

const API_KEY = process.env.X_API_KEY;
const API_SECRET = process.env.X_API_SECRET;

/**
 * Firebase Cloud Function: verifyGst
 * 
 * Proxies GST verification requests to sandbox.co.in API server-side,
 * avoiding CORS issues in the browser and keeping API secrets hidden.
 *
 * Called from Flutter with: FirebaseFunctions.instance.httpsCallable('verifyGst')
 */
exports.verifyGst = onCall({ cors: true }, async (request) => {
  // Ensure the user is authenticated before allowing the call
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "You must be logged in to verify GST numbers."
    );
  }

  const gstin = request.data?.gstin;
  if (!gstin || typeof gstin !== "string" || gstin.length !== 15) {
    throw new HttpsError(
      "invalid-argument",
      "A valid 15-digit GSTIN is required."
    );
  }

  if (!API_KEY || !API_SECRET) {
    throw new HttpsError(
      "internal",
      "API keys are not configured on the server."
    );
  }

  try {
    // Step 1: Authenticate with sandbox.co.in to get an access token
    const authResponse = await fetch(
      "https://api.sandbox.co.in/authenticate",
      {
        method: "POST",
        headers: {
          "x-api-key": API_KEY,
          "x-api-secret": API_SECRET,
        },
      }
    );

    if (!authResponse.ok) {
      const body = await authResponse.text();
      console.error("Auth failed:", body);
      throw new HttpsError("internal", "Authentication with GST API failed.");
    }

    const authData = await authResponse.json();
    const accessToken = authData?.data?.access_token;

    if (!accessToken) {
      throw new HttpsError("internal", "Could not retrieve access token.");
    }

    // Step 2: Fetch GST details using the access token
    const gstResponse = await fetch(
      "https://api.sandbox.co.in/gst/compliance/public/gstin/search",
      {
        method: "POST",
        headers: {
          Authorization: accessToken,
          "Content-Type": "application/json",
          "x-accept-cache": "false",
          "x-api-key": API_KEY,
          "x-api-version": "1.0.0",
        },
        body: JSON.stringify({ gstin }),
      }
    );

    const gstData = await gstResponse.json();

    if (gstResponse.ok && gstData?.code === 200) {
      const data = gstData?.data?.data ?? {};
      const businessName = data.lgnm ?? data.tradeNam ?? "";
      const addressObj = data.pradr?.addr ?? {};

      const building = addressObj.bno ?? "";
      const street = addressObj.flno ?? "";
      const address = [building, street].filter(Boolean).join(", ");

      return {
        success: true,
        name: businessName,
        address: address,
        city: addressObj.dst ?? "",
        state: addressObj.stcd ?? "",
        pincode: addressObj.pncd ?? "",
        phone: "",
        email: "",
      };
    } else {
      console.error("GST fetch failed:", gstData);
      throw new HttpsError(
        "not-found",
        gstData?.message ?? "Could not find GST details for this number."
      );
    }
  } catch (e) {
    if (e instanceof HttpsError) throw e;
    console.error("Unexpected error:", e);
    throw new HttpsError("internal", "An unexpected error occurred.");
  }
});
