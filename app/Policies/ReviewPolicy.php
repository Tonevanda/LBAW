<?php

namespace App\Policies;

use App\Models\User;
use App\Models\Review;
use Illuminate\Auth\Access\AuthorizationException;

class ReviewPolicy
{
    /**
     * Create a new policy instance.
     */
    public function __construct()
    {
        //
    }

    public function create(User $user): bool{
        if($user->isAdmin()){
            throw new AuthorizationException("Admins can't create reviews");
        }
        if($user->authenticated()->first()->isblocked){
            throw new AuthorizationException("Blocked users can't create reviews");
        }
        return true;
    }

    public function createReport(User $user, Review $review): bool{
        if($user->isAdmin()){
            throw new AuthorizationException("Admins can't report reviews");
        }

        if($user->id == $review->user_id){
            throw new AuthorizationException("Can't report own review");
        }
        return true;
    }

    public function update(User $user, Review $review): bool{
        if(!$user->isAdmin() && $user->id != $review->user_id){
            throw new AuthorizationException("Non admins can't edit other user's reviews");
        }
        return true;
    }

    public function destroy(User $user, Review $review): bool{
        if(!$user->isAdmin() && $review->user_id != $user->id){
            throw new AuthorizationException("A non admin can't delete other reviews");
        }
        return true;
    }
}
