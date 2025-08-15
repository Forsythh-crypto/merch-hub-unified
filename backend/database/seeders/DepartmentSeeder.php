<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Department;

class DepartmentSeeder extends Seeder
{
    /**
     * Seed the departments table with UDD academic divisions.
     */
    public function run(): void
    {
        $departments = [
            'School of Information Technology Education',
            'School of Teacher Education',
            'School of Criminology',
            'School of Health Sciences',
            'School of Humanities',
            'School of Engineering',
            'School of International Hospitality Management',
        ];

        foreach ($departments as $name) {
            Department::firstOrCreate(['name' => $name]);
        }
    }
}