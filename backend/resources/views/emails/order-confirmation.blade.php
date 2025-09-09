<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Order Confirmation</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #1E3A8A; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background: #f9f9f9; }
        .order-details { background: white; padding: 20px; margin: 20px 0; border-radius: 8px; }
        .status { display: inline-block; padding: 5px 15px; background: #F59E0B; color: white; border-radius: 20px; }
        .total { font-size: 18px; font-weight: bold; color: #1E3A8A; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>UDD Merch Hub</h1>
            <h2>Order Confirmation</h2>
        </div>
        
        <div class="content">
            <p>Dear {{ $user->name }},</p>
            
            <p>Thank you for your order! We have received your reservation and it is now being processed.</p>
            
            <div class="order-details">
                <h3>Order Details</h3>
                <p><strong>Order Number:</strong> {{ $order->order_number }}</p>
                <p><strong>Date:</strong> {{ $order->created_at->format('F j, Y g:i A') }}</p>
                <p><strong>Status:</strong> <span class="status">{{ $order->status_display }}</span></p>
                
                <h4>Product Information</h4>
                <p><strong>Product:</strong> {{ $listing->title }}</p>
                <p><strong>Department:</strong> {{ $department->name }}</p>
                <p><strong>Quantity:</strong> {{ $order->quantity }}</p>
                <p><strong>Price per item:</strong> ₱{{ number_format($listing->price, 2) }}</p>
                <p class="total"><strong>Total Amount:</strong> ₱{{ number_format($order->total_amount, 2) }}</p>
                
                @if($order->notes)
                <p><strong>Notes:</strong> {{ $order->notes }}</p>
                @endif
            </div>
            
            <h3>Payment Information</h3>
            <p><strong>Payment Method:</strong> Cash on Pickup</p>
            <p>Please bring the exact amount when picking up your order.</p>
            
            <h3>What's Next?</h3>
            <ol>
                <li>We will review your order and confirm it within 24 hours</li>
                <li>You will receive an email when your order is ready for pickup</li>
                <li>Please bring a valid ID when picking up your order</li>
                <li>Pickup location: {{ $department->name }} Office</li>
            </ol>
            
            <p>If you have any questions, please contact us at {{ $department->name }}.</p>
            
            <p>Thank you for choosing UDD Merch Hub!</p>
            
            <p>Best regards,<br>
            UDD Merch Hub Team</p>
        </div>
    </div>
</body>
</html>
