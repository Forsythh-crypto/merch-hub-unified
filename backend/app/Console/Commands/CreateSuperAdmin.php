<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\User;
use App\Models\Department;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class CreateSuperAdmin extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'user:create-superadmin 
                            {--name= : Name of the super admin}
                            {--email= : Email of the super admin}
                            {--password= : Password of the super admin}
                            {--department= : Department ID (optional)}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Create a super admin user';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info('Creating Super Admin User...');

        // Get input data
        $name = $this->option('name') ?: $this->ask('Enter super admin name');
        $email = $this->option('email') ?: $this->ask('Enter super admin email');
        $password = $this->option('password') ?: $this->secret('Enter super admin password');
        $departmentId = $this->option('department') ?: $this->askDepartment();

        // Validate input
        $validator = Validator::make([
            'name' => $name,
            'email' => $email,
            'password' => $password,
            'department_id' => $departmentId,
        ], [
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|min:6',
            'department_id' => 'nullable|exists:departments,id',
        ]);

        if ($validator->fails()) {
            $this->error('Validation failed:');
            foreach ($validator->errors()->all() as $error) {
                $this->error("  - $error");
            }
            return 1;
        }

        // Create the super admin
        try {
            $user = User::create([
                'name' => $name,
                'email' => $email,
                'password' => Hash::make($password),
                'role' => 'superadmin',
                'department_id' => $departmentId,
            ]);

            $this->info('✅ Super Admin created successfully!');
            $this->table(
                ['Field', 'Value'],
                [
                    ['ID', $user->id],
                    ['Name', $user->name],
                    ['Email', $user->email],
                    ['Role', $user->role],
                    ['Department ID', $user->department_id ?? 'None'],
                    ['Created At', $user->created_at],
                ]
            );

            return 0;
        } catch (\Exception $e) {
            $this->error('❌ Failed to create super admin: ' . $e->getMessage());
            return 1;
        }
    }

    private function askDepartment()
    {
        $departments = Department::orderBy('name')->get();
        
        if ($departments->isEmpty()) {
            $this->warn('No departments found. Super admin will be created without department.');
            return null;
        }

        $this->info('Available departments:');
        $this->table(
            ['ID', 'Name'],
            $departments->map(fn($dept) => [$dept->id, $dept->name])->toArray()
        );

        $departmentId = $this->ask('Enter department ID (or leave empty for no department)');
        
        return $departmentId ? (int) $departmentId : null;
    }
}
