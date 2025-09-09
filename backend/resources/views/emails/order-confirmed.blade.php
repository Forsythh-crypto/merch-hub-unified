<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Order Confirmed</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #059669; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background: #f9f9f9; }
        .order-details { background: white; padding: 20px; margin: 20px 0; border-radius: 8px; }
        .status { display: inline-block; padding: 5px 15px; background: #059669; color: white; border-radius: 20px; }
        .total { font-size: 18px; font-weight: bold; color: #1E3A8A; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>UDD Merch Hub</h1>
            <h2>✅ Order Confirmed</h2>
        </div>
        
        <div class="content">
            <p>Dear {{ $user->name }},</p>
            
            <p><strong>Great news!</strong> Your order has been confirmed and is now being processed.</p>
            
            <div class="order-details">
                <h3>Order Details</h3>
                <p><strong>Order Number:</strong> {{ $order->order_number }}</p>
                <p><strong>Status:</strong> <span class="status">{{ ucfirst(str_replace('_', ' ', $order->status)) }}</span></p>
                
                <h4>Product Information</h4>
                <p><strong>Product:</strong> {{ $listing->title }}</p>
                <p><strong>Department:</strong> {{ $department->name }}</p>
                <p><strong>Quantity:</strong> {{ $order->quantity }}</p>
                <p class="total"><strong>Total Amount:</strong> ₱{{ number_format($order->total_amount, 2) }}</p>
            </div>
            
            <h3>What's Next?</h3>
            <ol>
                <li>We are now preparing your order</li>
                <li>You will receive another email when your order is ready for pickup</li>
                <li>Please bring a valid ID when picking up your order</li>
                <li>Pickup location: {{ $department->name }} Office</li>
            </ol>
            
            <p>Thank you for choosing UDD Merch Hub!</p>
            
            <p>Best regards,<br>
            {{ $department->name }} Team</p>
        </div>
    </div>
</body>
</html>
