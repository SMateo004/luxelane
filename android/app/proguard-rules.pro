# flutter_stripe references Stripe's optional push-provisioning SDK
# (com.stripe:stripe-android-pushprovisioning), which this app does not use
# and does not ship. Without these rules R8 aborts the release build with
# "Missing class com.stripe.android.pushProvisioning.*".
-dontwarn com.stripe.android.pushProvisioning.**
-dontwarn com.reactnativestripesdk.pushprovisioning.**
