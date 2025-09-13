<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Order Ready for Pickup</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #059669; color: white; padding: 20px; text-align: center; }
        .content { padding: 20px; background: #f9f9f9; }
        .order-details { background: white; padding: 20px; margin: 20px 0; border-radius: 8px; }
        .status { display: inline-block; padding: 5px 15px; background: #059669; color: white; border-radius: 20px; }
        .total { font-size: 18px; font-weight: bold; color: #1E3A8A; }
        .pickup-info { background: #E0F2FE; padding: 15px; border-radius: 8px; border-left: 4px solid #0284C7; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>UDD Merch Hub</h1>
            <h2>🎉 Your Order is Ready for Pickup!</h2>
        </div>
        
        <div class="content">
            <p>Dear {{ $user->name }},</p>
            
            <p><strong>Great news!</strong> Your order is now ready for pickup. Please visit our office to collect your items.</p>
            
            <div class="order-details">
                <h3>Order Details</h3>
                <p><strong>Order Number:</strong> {{ $order->order_number }}</p>
                <p><strong>Status:</strong> <span class="status">{{ ucfirst(str_replace('_', ' ', $order->status)) }}</span></p>
                
                <h4>Product Information</h4>
                <p><strong>Product:</strong> {{ $listing->title }}</p>
                <p><strong>Department:</strong> {{ $department->name }}</p>
                <p><strong>Quantity:</strong> {{ $order->quantity }}</p>
                <p><strong>Original Amount:</strong> ₱{{ number_format($order->total_amount, 2) }}</p>
                <p><strong>Reservation Fee (35%):</strong> ₱{{ number_format($order->total_amount * 0.35, 2) }}</p>
                <p class="total"><strong>Remaining Balance:</strong> ₱{{ number_format($order->total_amount * 0.65, 2) }}</p>
                
                @if($order->pickup_date)
                <p><strong>Pickup Date:</strong> {{ \Carbon\Carbon::parse($order->pickup_date)->format('F j, Y g:i A') }}</p>
                @endif
            </div>
            
            <div class="pickup-info">
                <h3>📍 Pickup Information</h3>
                <p><strong>Location:</strong> {{ $department->name }} Office</p>
                <p><strong>Payment Method:</strong> Cash on Pickup</p>
                <p><strong>Required:</strong> Valid ID (Student ID, Driver's License, etc.)</p>
                <p><strong>Amount to Pay:</strong> ₱{{ number_format($order->total_amount * 0.65, 2) }}</p>
                <p><em>Note: 35% reservation fee already paid</em></p>
            </div>
            
            <h3>Important Reminders</h3>
            <ul>
                <li>Please bring the exact amount in cash</li>
                <li>Bring a valid ID for verification</li>
                <li>Orders must be picked up within 7 days</li>
                <li>Office hours: Monday to Friday, 8:00 AM - 5:00 PM</li>
            </ul>
            
            @if($order->notes)
            <h3>Additional Notes</h3>
            <p>{{ $order->notes }}</p>
            @endif
            
            <p>Thank you for choosing UDD Merch Hub!</p>
            
            <p>Best regards,<br>
            {{ $department->name }} Team</p>
        </div>
    </div>
</body>
</html>
