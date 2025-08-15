<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\User;
use Illuminate\Support\Facades\Hash;


class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Create Super Admin (department_id can be null for superadmin)
        User::firstOrCreate(
            ['email' => 'superadmin@example.com'],
            [
                'name' => 'Super Administrator',
                'password' => Hash::make('superadmin123'),
                'role' => 'superadmin',
                'department_id' => 1, // or null if you prefer
            ]
        );

        // Create Department Admin
        User::firstOrCreate(
            ['email' => 'admin@example.com'],
            [
                'name' => 'Department Admin',
                'password' => Hash::make('admin123'),
                'role' => 'admin',
                'department_id' => 1,
            ]
        );

        // Create Student User
        User::firstOrCreate(
            ['email' => 'student@example.com'],
            [
                'name' => 'Student User',
                'password' => Hash::make('student123'),
                'role' => 'student',
                'department_id' => 1,
            ]
        );
    }

}
