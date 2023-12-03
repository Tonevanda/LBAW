<?php

namespace App\Http\Controllers;

use App\Models\Review;
use Illuminate\Http\Request;

class ReviewController extends Controller
{
    public function store($user_id){
        $data = request()->validate([
            'product_id' => 'required',
            'title' => 'required',
            'description' => 'required',
            'rating' => 'required',
        ]);
        $data['user_id']=$user_id;
        $data['date']=date('Y-m-d H:i:s');
        Review::create($data);
        return redirect()->route('product', $data['product_id']);
    }
    public function destroy(Request $request, $review_id){
        $review = Review::findOrFail($review_id);
        $review->delete();
        return response()->json($review_id,204);
    }
    public function report(Request $request, $review_id){
        //é preciso adicionar um popup para o user escrever o motivo do report
        //$review = Review::findOrFail($review_id);
        //$review->reported = 1;
        //dd($review);
        //$review->save();
        return response()->json([], 201);
    }
    public function update(Request $request, $review_id){
        $review = Review::findOrFail($review_id);
        $data = $request->validate([
            //'title' => 'required',
            'description' => 'required',
            //'rating' => 'required',
        ]);
        $review->update($data);
        return response()->json($data['description'], 200);
    }
}
