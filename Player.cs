using Godot;
using System;

public class Player : Area2D
{
	[Export]
	public int moveSpeed = 400;
	
	private Vector2 _screenSize;

	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
		_screenSize = GetViewport().Size;   
	}

	public override void _Process(float delta)
	{
		Vector2 moveVector = modifyVelocityFromInput();
		playSpriteAnimation(moveVector);
		updatePosition(moveVector, delta);
	}
	
	private Vector2 modifyVelocityFromInput()
	{
		var velocity = new Vector2();
		
		if (Input.IsActionPressed("ui_right")) {
			velocity.x += 1;
		}
		if (Input.IsActionPressed("ui_left")) {
			velocity.x -= 1;
		}
		if (Input.IsActionPressed("ui_down")) {
			velocity.y += 1;
		}
		if (Input.IsActionPressed("ui_up")) {
			velocity.y -= 1;
		}
		
		return velocity.Normalized() * moveSpeed; 
	}
	
	private void playSpriteAnimation(Vector2 moveVector)
	{
		var animatedSprite = GetNode<AnimatedSprite>("AnimatedSprite");
		if (moveVector.Length() > 0) {
			animatedSprite.Play();
		} else { 
			animatedSprite.Stop();
		}
	}
	
	private void updatePosition(Vector2 moveVector, float delta)
	{
		Position += moveVector * delta;
		Position = new Vector2(
			x: Mathf.Clamp(Position.x, 0, _screenSize.x),
			y: Mathf.Clamp(Position.y, 0, _screenSize.y)
		);
	}
}
