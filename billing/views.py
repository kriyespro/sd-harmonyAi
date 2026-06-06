from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from . import services as billing_services


class BillingStatusView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(billing_services.get_billing_status(request.user))


class CreateOrderView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        order = billing_services.create_razorpay_order(request.user)
        return Response(order)


class VerifyPaymentView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        order_id = request.data.get('razorpay_order_id', '')
        payment_id = request.data.get('razorpay_payment_id', '')
        signature = request.data.get('razorpay_signature', '')

        if not order_id or not payment_id:
            return Response({'error': 'order_id and payment_id required'}, status=400)

        success, message = billing_services.verify_and_activate(
            request.user, order_id, payment_id, signature
        )
        if success:
            return Response({'message': message, 'is_premium': True})
        return Response({'error': message}, status=400)


class CancelSubscriptionView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        billing_services.cancel_subscription(request.user)
        return Response({'message': 'Subscription cancelled', 'is_premium': False})


class ActivateTestPremiumView(APIView):
    """Dev-only endpoint to test premium activation without real payment."""
    permission_classes = [IsAuthenticated]

    def post(self, request):
        from django.conf import settings
        if not settings.DEBUG:
            return Response({'error': 'Not available in production'}, status=403)
        billing_services._activate_premium(request.user, 'order_test_dev', 'pay_test_dev')
        return Response({'message': 'Test premium activated', 'is_premium': True})
