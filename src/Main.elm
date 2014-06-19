module Main where

import Graphics.WebGL (..)
import Math.Matrix4 (..)
import Keyboard
import Mouse
import Window

import Model
import Perception (..)
import Update
import Display

-- Pointer Lock information
port movement : Signal (Int,Int)
port isLocked : Signal Bool

-- Set up 3D world
inputs : Signal Model.Inputs
inputs =
  let dt = lift (\t -> t/500) (fps 60)
      dirKeys = merge Keyboard.arrows Keyboard.wasd
  in  merge (sampleOn dt <| lift3 Model.TimeDelta Keyboard.space dirKeys dt)
            (Model.Mouse <~ movement)

person : Signal Model.Person
person = foldp Update.step Model.defaultPerson inputs

main : Signal Element
main = world Display.ourEntities

world : Signal (Perception -> [Entity]) -> Signal Element
world entities =
  let t = foldp (+) 0 (fps 60)
  in  lift5 Display.scene entities Window.dimensions t isLocked person

-- Ability to request and exit. Click screen to request lock. Press escape to
-- give up the lock. This code can all be removed if you want to do this
-- differently.

port requestPointerLock : Signal ()
port requestPointerLock =
    dropWhen (lift2 (&&) Keyboard.shift isLocked) () Mouse.clicks

port exitPointerLock : Signal ()
port exitPointerLock =
    always () <~ keepIf (any (\x -> x == 27)) [] Keyboard.keysDown
