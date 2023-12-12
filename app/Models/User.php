<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;


class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    // Don't add create and update timestamps in database.

    protected $table = 'users';

    public $timestamps = false;

    protected $primaryKey = 'id';

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'profile_picture'
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
    ];

    public function isAdmin()
    {
        // Check if the user is part of the admin table
        return $this->admin()->exists();
    }

    public function reviews()
    {
        return $this->hasMany(Review::class, 'user_id');
    }

    public function getReviewFromProduct($productId)
    {
        return $this->reviews()->where('product_id', $productId);
    }

    public function admin()
    {
        return $this->hasOne(Admin::class, 'admin_id');
    }

    public function authenticated()
    {
        return $this->hasOne(Authenticated::class, 'user_id');
    }
}
