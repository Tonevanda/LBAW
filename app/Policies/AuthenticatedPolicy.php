<?php

namespace App\Policies;

use App\Models\User;
use App\Models\Authenticated;
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

    public function showAccountDetails(User $user, Authenticated $auth): bool
    {
        if(!$user->isAdmin() && $user->id != $auth->user_id){
            throw new AuthorizationException("Non Admins can't view other users account information");
        }
        return true;
    }

    public function updateLocation(User $user, Authenticated $auth): bool
    {
        if($user->id != $auth->user_id && !$user->isAdmin()){
            throw new AuthorizationException("you can't update the location of an account that isn't yours, unless you are an admin");
        }
        return true;
    }

}
