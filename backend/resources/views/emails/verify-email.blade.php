<!DOCTYPE html>
<html>

<head>
    <title>Verify Your Email</title>
</head>

<body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
    <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
        <h2 style="color: #1a56db;">Verify Your Email Address</h2>

        <p>Hello {{ $user->name }},</p>

        <p>Thank you for registering with Merch Hub Unified. Please use the verification code below to complete your
            registration:</p>

        <div style="background-color: #f3f4f6; padding: 20px; text-align: center; border-radius: 8px; margin: 20px 0;">
            <span style="font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #1a56db;">{{ $code }}</span>
        </div>

        <p>If you did not create an account, no further action is required.</p>

        <p>Regards,<br>Merch Hub Unified Team</p>
    </div>
</body>

</html>