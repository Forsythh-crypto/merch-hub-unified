<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use App\Models\User;

use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    public function forgotPassword(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email|exists:users,email',
        ]);

        $user = User::where('email', $validated['email'])->first();

        // Generate new verification code
        $code = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        $user->verification_code = $code;
        $user->save();

        // Respond immediately to avoid timing attacks/leaks, but still send the email
        // In a real production app, this should be queued.
        $this->sendVerificationEmail($user, $code);

        return response()->json([
            'message' => 'If an account exists with this email, a verification code has been sent.',
        ]);
    }

    public function verifyResetCode(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email|exists:users,email',
            'code' => 'required|string|size:6',
        ]);

        $user = User::where('email', $validated['email'])->first();

        if ($user->verification_code !== $validated['code']) {
            return response()->json(['message' => 'Invalid verification code'], 400);
        }

        return response()->json([
            'message' => 'Verification code is valid',
            'valid' => true
        ]);
    }

    public function resetPassword(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email|exists:users,email',
            'code' => 'required|string|size:6',
            'password' => 'required|string|min:6|confirmed',
        ]);

        $user = User::where('email', $validated['email'])->first();

        if ($user->verification_code !== $validated['code']) {
            return response()->json(['message' => 'Invalid verification code'], 400);
        }

        // Update password and clear verification code
        $user->password = Hash::make($validated['password']);
        $user->verification_code = null;
        $user->save();

        return response()->json([
            'message' => 'Password reset successfully. You can now login with your new password.',
        ]);
    }
    public function register(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|unique:users',
            'password' => 'required|string|min:6|confirmed',
            'department_id' => 'required|exists:departments,id',
            'role' => 'required|in:student,admin,superadmin',
            'id_number' => ['nullable', 'string', 'regex:/^\d{2}-\d{4}-\d{3}$/', 'unique:users,id_number'],
        ]);

        $code = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'department_id' => $validated['department_id'],
            'role' => $validated['role'],
            'id_number' => $validated['id_number'],
            'verification_code' => $code,
        ]);

        // Send verification email
        $this->sendVerificationEmail($user, $code);

        return response()->json([
            'message' => 'Registration successful. Please verify your email.',
            'email' => $user->email,
        ], 201);
    }

    public function verifyEmail(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email|exists:users,email',
            'code' => 'required|string|size:6',
        ]);

        $user = User::where('email', $validated['email'])->first();

        if ($user->email_verified_at) {
            return response()->json(['message' => 'Email already verified'], 400);
        }

        if ($user->verification_code !== $validated['code']) {
            return response()->json(['message' => 'Invalid verification code'], 400);
        }

        // Verify user
        $user->email_verified_at = now();
        $user->verification_code = null;
        $user->save();

        // Load department relationship
        $user->load('department');

        // Generate token
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Email verified successfully',
            'user' => $user->getSessionData(),
            'token' => $token,
        ]);
    }

    public function resendVerificationCode(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email|exists:users,email',
        ]);

        $user = User::where('email', $validated['email'])->first();

        if ($user->email_verified_at) {
            return response()->json(['message' => 'Email already verified'], 400);
        }

        $code = str_pad(random_int(0, 999999), 6, '0', STR_PAD_LEFT);
        $user->verification_code = $code;
        $user->save();

        $this->sendVerificationEmail($user, $code);

        return response()->json(['message' => 'Verification code resent']);
    }

    private function sendVerificationEmail($user, $code)
    {
        try {
            Mail::send('emails.verify-email', ['user' => $user, 'code' => $code], function ($message) use ($user) {
                $message->to($user->email)
                    ->subject('Verify Your Email - Merch Hub Unified');
            });
        } catch (\Exception $e) {
            // Log error but don't fail the request
            \Log::error('Failed to send verification email: ' . $e->getMessage());
        }
    }


    public function login(Request $request)
    {
        $credentials = $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        if (!Auth::attempt($credentials)) {
            return response()->json(['message' => 'Invalid credentials'], 401);
        }

        $user = Auth::user();

        if (!$user->email_verified_at) {
            return response()->json([
                'message' => 'Email not verified',
                'email_not_verified' => true
            ], 403);
        }
        // Load department relationship for session data
        $user->load('department');

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'user' => $user->getSessionData(),
            'token' => $token,
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->tokens()->delete();
        return response()->json(['message' => 'Logged out']);
    }

    public function updateProfile(Request $request)
    {
        $user = Auth::user();

        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'password' => 'sometimes|nullable|string|min:6|confirmed',
            'id_number' => ['sometimes', 'nullable', 'string', 'regex:/^\d{2}-\d{4}-\d{3}$/', 'unique:users,id_number,' . $user->id],
        ]);

        if ($request->has('name')) {
            $user->name = $validated['name'];
        }

        if ($request->has('id_number')) {
            $user->id_number = $validated['id_number'];
        }

        if ($request->has('password') && !empty($validated['password'])) {
            $request->validate([
                'current_password' => 'required|string',
            ]);

            if (!Hash::check($request->current_password, $user->password)) {
                return response()->json(['message' => 'Incorrect current password'], 400);
            }

            $user->password = Hash::make($validated['password']);
        }

        $user->save();
        $user->load('department');

        return response()->json([
            'message' => 'Profile updated successfully',
            'user' => $user->getSessionData(),
        ]);
    }
}