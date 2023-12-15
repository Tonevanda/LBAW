<?php

namespace App\Policies;

use App\Models\User;
use App\Models\Wallet;
use Illuminate\Auth\Access\AuthorizationException;

class WalletPolicy
{
    /**
     * Create a new policy instance.
     */
    public function __construct()
    {
        //
    }

    public function show(User $user, Wallet $wallet): bool{
        if(!$user->isAdmin() && $user->id != $wallet->user_id){
            throw new AuthorizationException("Non admins can't view other user's wallets");
        }
        return true;
    }
}
