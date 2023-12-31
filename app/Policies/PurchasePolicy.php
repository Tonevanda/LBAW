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
        if($user->id != $purchase->user_id && !$user->isAdmin()){
            throw new AuthorizationException("The person making the purchase isn't the one in the account currently logged in");
        }
        return true;
    }


    public function create(User $user, $user_id): bool
    {
        
        if($user->isAdmin()){
            throw new AuthorizationException("Admins can't make purchases");
        }

        if($user->id != $user_id){
            throw new AuthorizationException("You can't make a purchase if it's not your account");
        }
        return true;
    }

    public function update(User $user, Purchase $purchase, $user_id): bool
    {
        if($user->isAdmin()){
            throw new AuthorizationException("Admins cant make cancels or refunds");
        }
        if($user->id != $purchase->user_id){
            throw new AuthorizationException("You can't cancel or refund a purchase if it's not your account");
        }
        if($user->id != $user_id){
            throw new AuthorizationException("This isn't your purchase");
        }
        if($purchase->stage_state != "delivered" && now()->diffInMinutes($purchase->orderarrivedat) > 5){
            throw new AuthorizationException("You can't refund after the purchase after 5 days");
        }
        return true;
    }
    
}
