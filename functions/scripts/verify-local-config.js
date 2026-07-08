const fs = require("fs");

const credentialsPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || "";
const stripeSecretKey = process.env.STRIPE_SECRET_KEY || "";

let hasError = false;

function fail(message) {
  console.error(`ERROR: ${message}`);
  hasError = true;
}

function ok(message) {
  console.log(`OK: ${message}`);
}

console.log("Checking local Firebase Functions configuration...");

if (!credentialsPath) {
  fail(
      "GOOGLE_APPLICATION_CREDENTIALS is not set. Set it to a real Firebase service-account JSON before running Functions locally.",
  );
} else if (credentialsPath.includes("path\\to\\your-service-account-file.json")) {
  fail(
      `GOOGLE_APPLICATION_CREDENTIALS still points to the placeholder path: ${credentialsPath}`,
  );
} else if (!fs.existsSync(credentialsPath)) {
  fail(
      `GOOGLE_APPLICATION_CREDENTIALS points to a missing file: ${credentialsPath}`,
  );
} else {
  ok(`Found service-account file at ${credentialsPath}`);
}

if (!stripeSecretKey) {
  fail(
      "STRIPE_SECRET_KEY is not set. Set it before testing payment intents locally.",
  );
} else if (!stripeSecretKey.startsWith("sk_")) {
  fail("STRIPE_SECRET_KEY does not look like a Stripe secret key.");
} else {
  ok("STRIPE_SECRET_KEY is present.");
}

if (hasError) {
  console.error("");
  console.error("Fix the items above, then run:");
  console.error("  npm run serve:checked");
  process.exit(1);
}

console.log("");
console.log("Local Functions config looks good.");
