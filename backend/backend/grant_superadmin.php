<?php

require_once 'vendor/autoload.php';

$app = require_once 'bootstrap/app.php';
$app->boot();

use App\Models\User;

$email = 'superadmin@example.com';
$user = User::where('email', $email)->first();

if ($user) {
    $user->update(['role' => 'superadmin']);
    echo "✅ SuperAdmin role granted to: {$user->name} ({$user->email})\n";
    echo "Current role: {$user->role}\n";
} else {
    echo "❌ User not found with email: {$email}\n";
    echo "Available users:\n";
    $users = User::all(['id', 'name', 'email', 'role']);
    foreach ($users as $u) {
        echo "- {$u->name} ({$u->email}) - {$u->role}\n";
    }
}
