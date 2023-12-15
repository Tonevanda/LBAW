<?php

namespace App\Policies;

use App\Models\User;
use Illuminate\Auth\Access\AuthorizationException;

class ReviewPolicy
{
    /**
     * Create a new policy instance.
     */
    public function __construct()
    {
        //
    }

    public function create(User $user): bool{
        if($user->isAdmin()){
            throw new AuthorizationException("Admins can't create reviews");
        }
        return true;
    }
}
