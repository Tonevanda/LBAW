<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use Illuminate\Support\Facades\Auth;

class AdminOrAuth
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle($request, Closure $next)
    {
        $userId = $request->route('user_id'); // replace 'user_id' with the actual name of the route parameter
        $user = Auth::user();
        #dd($user);
        if ($user->isAdmin() ) {
            return $next($request);
        }
        else if ($user->id == $userId) {
            return $next($request);
        }
        return redirect('login');
    }
}
