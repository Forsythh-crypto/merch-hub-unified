<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class RoleMiddleware
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next, ...$roles): Response
    {
        \Log::info('RoleMiddleware: Checking auth for path: ' . $request->path());
        
        if (!$request->user()) {
            \Log::warning('RoleMiddleware: No authenticated user');
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $user = $request->user();
        \Log::info('RoleMiddleware: User role: ' . $user->role . ', Required roles: ' . implode(',', $roles));
        
        // Check if user has any of the required roles
        if (!in_array($user->role, $roles)) {
            \Log::warning('RoleMiddleware: Insufficient permissions for user: ' . $user->email);
            return response()->json(['message' => 'Forbidden - Insufficient permissions'], 403);
        }

        \Log::info('RoleMiddleware: Access granted for user: ' . $user->email);
        return $next($request);
    }
}
