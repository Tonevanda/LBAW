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
        return view('wallet.show', [
            'wallet' => $wallet
        ]);
    }


    public function update(Request $request, $user_id){
        $data = $request->validate([
            'money' => 'required',
        ]);

        $wallet = Wallet::findOrFail($user_id);
        $currency = $wallet->currency()->first();

        try{
            $this->authorize('update', $wallet);
        }catch(AuthorizationException $e){
            return response()->json($e->getMessage(), 301);
        }

        $data['money'] = $wallet->money + intval($data['money'])*100;

        $wallet->update($data);

        $data['money'] = $data['money']/100;
        $data['money'] = number_format($data['money'], 2, ',', '.');
        $data['currencySymbol'] = $currency->currency_symbol;
        
        return response()->json($data, 200);
    }
}
