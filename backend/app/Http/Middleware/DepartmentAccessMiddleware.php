<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class DepartmentAccessMiddleware
{
    /**
     * Handle an incoming request.
     * Checks if user can access/manage a specific department
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        if (!$request->user()) {
            return response()->json(['message' => 'Unauthorized'], 401);
        }

        $user = $request->user();
        
        // Get department ID from route parameter or request data
        $departmentId = $request->route('department_id') ?? 
                       $request->input('department_id') ?? 
                       $request->route('departmentId');

        if (!$departmentId) {
            return response()->json(['message' => 'Department ID required'], 400);
        }

        // Check if user can manage this department
        if (!$user->canManageDepartment((int) $departmentId)) {
            return response()->json([
                'message' => 'Forbidden - Cannot access this department'
            ], 403);
        }

        return $next($request);
    }
}
