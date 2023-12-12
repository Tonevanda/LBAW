<?php

namespace App\Policies;

use App\Models\User;
use App\Models\Purchase;

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
        // Any (authenticated) user can list its own cards.
        return $user->id === $purchase->user_id;
    }
    
}
