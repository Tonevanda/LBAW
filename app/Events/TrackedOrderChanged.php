<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PresenceChannel;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class TrackedOrderChanged
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public $message;
    public $product_id;


    /**
     * Create a new event instance.
     */
    public function __construct($product_id)
    {
        error_log($product_id);
        $this->product_id = $product_id;
        $this->message = 'Your tracked order has changed';

    }

    /**
     * Get the channels the event should broadcast on.
     *
     * @return array<int, \Illuminate\Broadcasting\Channel>
     */
    // You should specify the name of the channel created in Pusher.
    public function broadcastOn(): array {
        return ['users'];
    }

    // You should specify the name of the generated notification.
    public function broadcastAs() {
        return 'changed-tracked-order-notification';
    }
}
