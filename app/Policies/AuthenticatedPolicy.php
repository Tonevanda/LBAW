<?php

namespace App\Policies;

use App\Models\User;
use Illuminate\Auth\Access\AuthorizationException;

class AuthenticatedPolicy
{
    /**
     * Create a new policy instance.
     */
    public function __construct()
    {
        //
    }

    public function list(User $user): bool
    {
        if(!$user->isAdmin()){
            throw new AuthorizationException("Non Admins can't view other users account information");
        }
        return true;
    }

}
