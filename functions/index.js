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

/**
 * Firebase Cloud Function: sendInvoiceSms
 *
 * Sends an SMS to the client with a link to their invoice.
 * Requires an SMS provider like Twilio to be configured via environment variables.
 */
exports.sendInvoiceSms = onCall({ cors: true }, async (request) => {
  // Ensure the user is authenticated before allowing the call
  if (!request.auth) {
    throw new HttpsError(
      "unauthenticated",
      "You must be logged in to send an SMS."
    );
  }

  const phone = request.data?.phone;
  const message = request.data?.message;

  if (!phone || typeof phone !== "string" || phone.trim() === "") {
    throw new HttpsError(
      "invalid-argument",
      "A valid destination phone number is required."
    );
  }

  if (!message || typeof message !== "string" || message.trim() === "") {
    throw new HttpsError(
      "invalid-argument",
      "An SMS message body is required."
    );
  }

  // Provider configuration (defaults to Twilio placeholder)
  const TWILIO_SID = process.env.TWILIO_SID;
  const TWILIO_AUTH = process.env.TWILIO_AUTH;
  const TWILIO_FROM = process.env.TWILIO_FROM; // Server sender number

  if (!TWILIO_SID || !TWILIO_AUTH || !TWILIO_FROM) {
    // Return success in the stub so the UI doesn't crash while the dev sets up a provider.
    console.warn("SMS requested but Twilio credentials are not configured.");
    console.log(`\n[STUB] Would have sent SMS to ${phone}:\n${message}\n`);
    
    return { 
      success: true, 
      stub: true,
      message: "SMS provider not configured (logged to server console instead)." 
    }; 
  }

  try {
    const twilio = require("twilio")(TWILIO_SID, TWILIO_AUTH);
    const response = await twilio.messages.create({
      body: message,
      from: TWILIO_FROM,
      to: phone,
    });
    
    console.log(`Successfully sent SMS via Twilio using SID: ${response.sid}`);
    return { success: true, messageId: response.sid };
  } catch (e) {
    console.error("SMS sending failed:", e);
    throw new HttpsError("internal", "Failed to send SMS via provider.");
  }
});
