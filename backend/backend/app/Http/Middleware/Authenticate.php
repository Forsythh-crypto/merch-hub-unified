<?php

namespace App\Http\Middleware;

use Illuminate\Auth\Middleware\Authenticate as Middleware;
use Illuminate\Http\Request;

class Authenticate extends Middleware
{
    /**
     * Get the path the user should be redirected to when they are not authenticated.
     */
    protected function redirectTo(Request $request): ?string
    {
        // For API routes, return null so it throws an exception instead of redirecting
        if ($request->expectsJson() || $request->is('api/*')) {
            return null;
        }

        // For web routes, redirect to login (though we don't have web routes in this project)
        return route('login');
    }
}
