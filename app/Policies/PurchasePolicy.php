<?php

namespace App\Policies;

use App\Models\User;
use App\Models\Purchase;
use Illuminate\Auth\Access\AuthorizationException;

class PurchasePolicy
{
    /**
     * Create a new policy instance.
     */
    public function __construct()
    {
        //
    }

    public function list(User $user, Purchase $purchase): bool
    {
        if($user->id != $purchase->user_id){
            throw new AuthorizationException("The person making the purchase isn't the one in the account currently logged in");
        }
        return true;
    }


    public function create(User $user): bool
    {
        
        if($user->isAdmin()){
            throw new AuthorizationException("Admins can't make purchases");
        }
        return true;
    }
    
}
