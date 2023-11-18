<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Models\User;

class CheckAdmin
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next)
    {
        // Check if the user is authenticated
        if (Auth::check()) {
            // Get the authenticated user
            $user = Auth::user();

            // Check if the user is an admin
            if ($user->isAdmin()) {
                return $next($request);
            }

            // Redirect or handle unauthorized access
            return redirect()->route('all-products'); // Change 'unauthorized' to your desired route
        }

        // Handle the case when the user is not authenticated
        return redirect()->route('login'); // Change 'login' to your login route
    }
}
