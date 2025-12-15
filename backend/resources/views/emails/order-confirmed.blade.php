<!DOCTYPE html>
<html>

<head>
    <meta charset="utf-8">
    <title>Order Confirmed</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
        }

        .container {
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
        }

        .header {
            background: #059669;
            color: white;
            padding: 20px;
            text-align: center;
        }

        .content {
            padding: 20px;
            background: #f9f9f9;
        }

        .order-details {
            background: white;
            padding: 20px;
            margin: 20px 0;
            border-radius: 8px;
        }

        .status {
            display: inline-block;
            padding: 5px 15px;
            background: #059669;
            color: white;
            border-radius: 20px;
        }

        .total {
            font-size: 18px;
            font-weight: bold;
            color: #1E3A8A;
        }
    </style>
</head>

<body>
    <div class="container">
        <div class="header">
            <h1>UDD Essentials</h1>
            <h2>Order Confirmed</h2>
        </div>

        <div class="content">
            <p>Dear {{ $user->name }},</p>

            <p><strong>Great news!</strong> Your order has been confirmed and is now being processed.</p>

            <div class="order-details">
                <h3>Order Details</h3>
                <p><strong>Order Number:</strong> {{ $order->order_number }}</p>
                <p><strong>Status:</strong> <span
                        class="status">{{ ucfirst(str_replace('_', ' ', $order->status)) }}</span></p>

                <h4>Product Information</h4>
                @if($order->items && $order->items->count() > 0)
                    <table style="width: 100%; border-collapse: collapse; margin-bottom: 15px;">
                        <thead>
                            <tr style="background: #f0f0f0; text-align: left;">
                                <th style="padding: 8px; border-bottom: 1px solid #ddd;">Product</th>
                                <th style="padding: 8px; border-bottom: 1px solid #ddd;">Size</th>
                                <th style="padding: 8px; border-bottom: 1px solid #ddd;">Qty</th>
                                <th style="padding: 8px; border-bottom: 1px solid #ddd;">Price</th>
                                <th style="padding: 8px; border-bottom: 1px solid #ddd;">Total</th>
                            </tr>
                        </thead>
                        <tbody>
                            @foreach($order->items as $item)
                                <tr>
                                    <td style="padding: 8px; border-bottom: 1px solid #eee;">
                                        {{ $item->listing->title ?? 'Item' }}</td>
                                    <td style="padding: 8px; border-bottom: 1px solid #eee;">{{ $item->size ?? '-' }}</td>
                                    <td style="padding: 8px; border-bottom: 1px solid #eee;">{{ $item->quantity }}</td>
                                    <td style="padding: 8px; border-bottom: 1px solid #eee;">
                                        ₱{{ number_format($item->price, 2) }}</td>
                                    <td style="padding: 8px; border-bottom: 1px solid #eee;">
                                        ₱{{ number_format($item->subtotal, 2) }}</td>
                                </tr>
                            @endforeach
                        </tbody>
                    </table>
                @elseif($listing)
                    <p><strong>Product:</strong> {{ $listing->title }}</p>
                    <p><strong>Quantity:</strong> {{ $order->quantity }}</p>
                    <p><strong>Price per item:</strong> ₱{{ number_format($listing->price, 2) }}</p>
                @endif

                <p><strong>Department:</strong> {{ $department->name }}</p>
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