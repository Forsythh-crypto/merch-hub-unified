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
            [
                'name' => 'School of Business and Accountancy',
                'logo_path' => 'sba.png'
            ],
            [
                'name' => 'School of Information Technology Education',
                'logo_path' => 'site.png'
            ],
            [
                'name' => 'School of Teacher Education',
                'logo_path' => 'ste.png'
            ],
            [
                'name' => 'School of Criminology',
                'logo_path' => 'soc.png'
            ],
            [
                'name' => 'School of Health Sciences',
                'logo_path' => 'sohs.png'
            ],
            [
                'name' => 'School of Humanities',
                'logo_path' => 'soh.png'
            ],
            [
                'name' => 'School of Engineering',
                'logo_path' => 'soe.png'
            ],
            [
                'name' => 'School of International Hospitality Management',
                'logo_path' => 'sihm.png'
            ],
            [
                'name' => 'Official UDD Merch',
                'logo_path' => 'udd_merch.png'
            ],
        ];

        foreach ($departments as $department) {
            Department::firstOrCreate(
                ['name' => $department['name']],
                ['logo_path' => $department['logo_path']]
            );
        }
    }
}