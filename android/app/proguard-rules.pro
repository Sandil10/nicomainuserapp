# Stripe SDK
-keep class com.stripe.android.pushProvisioning.** { *; }
-dontwarn com.stripe.android.pushProvisioning.**

# Keep all Stripe Push Provisioning classes
-keep class com.stripe.android.pushProvisioning.** { *; }

# Keep React Native Stripe SDK classes
-keep class com.reactnativestripesdk.** { *; }

# Keep all Parcelable classes used by Stripe
-keep class com.stripe.android.** implements android.os.Parcelable { *; }

# Optional: Keep annotations to avoid reflection issues
-keepattributes *Annotation*
