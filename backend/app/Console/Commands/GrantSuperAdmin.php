<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\User;

class GrantSuperAdmin extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'grant:superadmin {email}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Grant SuperAdmin role to a user by email';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $email = $this->argument('email');
        $user = User::where('email', $email)->first();

        if ($user) {
            $user->update(['role' => 'superadmin']);
            $this->info("✅ SuperAdmin role granted to: {$user->name} ({$user->email})");
            $this->info("Current role: {$user->role}");
        } else {
            $this->error("❌ User not found with email: {$email}");
            $this->info("Available users:");
            $users = User::all(['id', 'name', 'email', 'role']);
            foreach ($users as $u) {
                $this->line("- {$u->name} ({$u->email}) - {$u->role}");
            }
        }
    }
}
