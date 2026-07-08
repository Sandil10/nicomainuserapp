const functions = require("firebase-functions");
// Read the Stripe secret from the environment — never hardcode it.
// Set it with:  firebase functions:config:set stripe.secret="sk_live_..."
// or an environment variable STRIPE_SECRET_KEY in your deploy environment.
const stripeSecretKey =
  process.env.STRIPE_SECRET_KEY ||
  (functions.config().stripe && functions.config().stripe.secret) ||
  "";
if (!stripeSecretKey) {
  throw new Error(
    "Missing STRIPE_SECRET_KEY. Set the Stripe secret key via environment " +
    "variable or firebase functions config before deploying.",
  );
}
const stripe = require("stripe")(stripeSecretKey);
const cors = require("cors")({ origin: true });

exports.createPaymentIntent = functions.https.onRequest(async (req, res) => {
  cors(req, res, async () => {
    try {
      const { amount, currency, metadata } = req.body;

      // Validate amount
      if (!amount || amount <= 0) {
        return res.status(400).send({ error: "Invalid amount" });
      }

      const paymentIntent = await stripe.paymentIntents.create({
        amount: amount,               // Amount in cents
        currency: currency || "eur",  // Default to EUR
        metadata: metadata || {},
        automatic_payment_methods: { enabled: true },
      });

      return res.status(200).send({ 
        clientSecret: paymentIntent.client_secret,
        id: paymentIntent.id
      });

    } catch (error) {
      console.error("Stripe Error:", error);
      return res.status(500).send({ error: error.message });
    }
  });
});
