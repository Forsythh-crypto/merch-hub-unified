<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Category;

class CategorySeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $categories = ['Clothing', 'Accessories', 'Supplies', 'Tech'];

        foreach ($categories as $name) {
            Category::firstOrCreate(
                ['name' => $name],
                ['created_at' => now(), 'updated_at' => now()]
            );
        }
    }
}