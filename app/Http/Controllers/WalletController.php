<?php

namespace App\Http\Controllers;

use App\Models\Wallet;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Http\Request;

class WalletController extends Controller
{
    public function show($user_id)
    {

        $wallet = Wallet::filter($user_id)->first();


        try{
            $this->authorize('show', $wallet);
        }catch(AuthorizationException $e){
            return redirect()->route('all-products');
        }

        $currencySymbols = [
            'euro' => '€',
            'pound' => '£',
            'dollar' => '$',
            'rupee' => '₹',
            'yen' => '¥',
        ];
        $wallet->currencySymbol = $currencySymbols[$wallet->currency_type] ?? '';
        return view('wallet.show', [
            'wallet' => $wallet
        ]);
    }


    public function update(Request $request, $user_id){
        return response()->json([], 200);
    }
}
