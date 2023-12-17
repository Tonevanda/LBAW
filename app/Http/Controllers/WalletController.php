<?php

namespace App\Http\Controllers;

use App\Models\Wallet;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Http\Request;

class WalletController extends Controller
{
    public function show($user_id)
    {

        $wallet = Wallet::findOrFail($user_id);


        try{
            $this->authorize('show', $wallet);
        }catch(AuthorizationException $e){
            return redirect()->route('all-products');
        }

        $wallet->money = $wallet->money/100;

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
        $data = $request->validate([
            'money' => 'required',
        ]);

        $wallet = Wallet::findOrFail($user_id);

        $data['money'] = $wallet->money + intval($data['money'])*100;

        $wallet->update($data);

        $currencySymbols = [
            'euro' => '€',
            'pound' => '£',
            'dollar' => '$',
            'rupee' => '₹',
            'yen' => '¥',
        ];
        $data['money'] = $data['money']/100;
        $data['money'] = number_format($data['money'], 2, ',', '.');
        $data['currencySymbol'] = $currencySymbols[$wallet->currency_type] ?? '';
        
        return response()->json($data, 200);
    }
}
