<?php

namespace App\Http\Controllers;

use App\Models\Wallet;
use Illuminate\Http\Request;

class WalletController extends Controller
{
    public function show($user_id)
    {
        $wallet = Wallet::filter($user_id)->first();
        $wallet->money = number_format($wallet->money, 2, ',', '.');
        return view('wallet.show', [
            'wallet' => $wallet
        ]);
    }
}