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


    public function update(User $user, Wallet $wallet): bool{
        if($user->isAdmin()){
            throw new AuthorizationException("Admins can't add funds to wallet");
        }
        if($user->id != $wallet->user_id){
            throw new AuthorizationException("This isn't your wallet");
        }
        return true;
    }
}
