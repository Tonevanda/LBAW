<?php

namespace App\Http\Controllers;

use App\Models\Review;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Http\Request;

class ReviewController extends Controller
{

    /*public function show(Request $request, $user_id){
        return 
    }*/
    public function store(Request $request, $user_id){
        $data = $request->validate([
            'product_id' => 'required',
            'title' => 'required',
            'description' => 'required',
            'rating' => 'required',
        ]);
        try{
            $this->authorize('create', Review::class);
        }catch(AuthorizationException $e){
            return response()->json($e->getMessage(), 301);
        }
        $data['user_id']=$user_id;
        $data['date']=date('Y-m-d H:i:s');
        $review = Review::create($data);
        $data['review_id'] = $review->id;
        $user = $review->getAuthor()->first();
        $data['profile_picture'] = $user->profile_picture;
        $data['name'] = $user->name;
        return response()->json($data, 201);
    }
    public function destroy(Request $request, $review_id){
        $data = $request->validate([
            'product_id' => 'required',
        ]);
        $review = Review::findOrFail($review_id);
        try{
            $this->authorize('destroy', $review);
        }catch(AuthorizationException $e){
            return response()->json(['message' => $e->getMessage(), 'review_id' => $review_id], 301);
        }
        $review->delete();
        $data['review_id'] = $review_id;
        $data['user_id'] = $review->user_id;
        $user = $review->getAuthor()->first();
        $data['profile_picture'] = $user->profile_picture;
        $data['name'] = $user->name;
        return response()->json($data,200);
    }
    public function report(Request $request, $review_id){
        //é preciso adicionar um popup para o user escrever o motivo do report
        $review = Review::findOrFail($review_id);
        try{
            $this->authorize('createReport', $review);
        }catch(AuthorizationException $e){
            return response()->json($e->getMessage(), 301);
        }
        //$review->reported = 1;
        //dd($review);
        //$review->save();
        return response()->json([], 201);
    }
    public function update(Request $request, $review_id){
        $review = Review::findOrFail($review_id);
        $data = $request->validate([
            'title' => 'required',
            'description' => 'required',
            //'rating' => 'required',
        ]);
        try{
            $this->authorize('update', $review);
        }catch(AuthorizationException $e){
            return response()->json($e->getMessage(), 301);
        }
        $review->update($data);
        return response()->json($data['description'], 200);
    }
}
