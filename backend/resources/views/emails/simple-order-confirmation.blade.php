<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Order Confirmation</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
        }
        .header {
            background-color: #4F46E5;
            color: white;
            padding: 20px;
            text-align: center;
            border-radius: 8px 8px 0 0;
        }
        .content {
            background-color: #f9f9f9;
            padding: 20px;
            border-radius: 0 0 8px 8px;
        }
        .order-number {
            background-color: #10B981;
            color: white;
            padding: 10px;
            border-radius: 4px;
            text-align: center;
            font-size: 18px;
            font-weight: bold;
            margin: 20px 0;
        }
        .order-details {
            background-color: white;
            padding: 20px;
            border-radius: 4px;
            margin: 20px 0;
        }
        .product-info {
            border-bottom: 1px solid #eee;
            padding-bottom: 15px;
            margin-bottom: 15px;
        }
        .total {
            font-size: 18px;
            font-weight: bold;
            color: #4F46E5;
        }
        .status {
            background-color: #F59E0B;
            color: white;
            padding: 8px 16px;
            border-radius: 20px;
            display: inline-block;
            font-weight: bold;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            color: #666;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🎉 Order Confirmation</h1>
        <p>Thank you for your order!</p>
    </div>

    <div class="content">
        <div class="order-number">
            Order #{{ $order->order_number }}
        </div>

        <div class="order-details">
            <h3>Order Details</h3>
            
            <div class="product-info">
                <strong>Product:</strong> {{ $listing->title }}<br>
                <strong>Department:</strong> {{ $department->name }}<br>
                @if($order->size)
                    <strong>Size:</strong> {{ $order->size }}<br>
                @endif
                <strong>Quantity:</strong> {{ $order->quantity }}<br>
                <strong>Price:</strong> ₱{{ number_format($listing->price, 2) }}
            </div>

            <div class="total">
                Total Amount: ₱{{ number_format($order->total_amount, 2) }}
            </div>

            <div style="margin-top: 20px;">
                <span class="status">{{ ucfirst($order->status) }}</span>
            </div>

            @if($order->notes)
                <div style="margin-top: 15px;">
                    <strong>Notes:</strong> {{ $order->notes }}
                </div>
            @endif
        </div>

        <div style="background-color: #EFF6FF; padding: 15px; border-radius: 4px; margin: 20px 0;">
            <h4>📋 What's Next?</h4>
            <p>Your order has been received and is being processed. You will receive another email when your order is ready for pickup.</p>
        </div>

        <div style="background-color: #FEF3C7; padding: 15px; border-radius: 4px; margin: 20px 0;">
            <h4>📍 Pickup Information</h4>
            <p><strong>Location:</strong> {{ $department->name }} Office<br>
            <strong>Payment Method:</strong> Cash on Pickup<br>
            <strong>Please bring:</strong> This order confirmation email or your order number</p>
        </div>
    </div>

    <div class="footer">
        <p>Thank you for choosing Merch Hub!</p>
        <p>If you have any questions, please contact the {{ $department->name }} office.</p>
    </div>
</body>
</html>
