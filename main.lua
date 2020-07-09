-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

local physics = require( "physics" )
physics.start()
physics.setGravity( 0, 0 )

-- Seed the random number generator
math.randomseed( os.time() )

-- Configure image sheet
local sheetOptions =
{
    frames =
    {
        {   -- 1) virus 1
            x = 20,
            y = 19,
            width = 162,
            height = 155
        },
        {   -- 2) virus 2
            x = 16,
            y = 180,
            width = 170,
            height = 150
        },
        {   -- 3) virus 3
            x = 30,
            y = 340,
            width = 147,
            height = 140
        },
    },
}

local objectVirus = graphics.newImageSheet( "Asset/corona.png", sheetOptions ) -- Menentukan gambar virus di satu gambar


-- Initialize variables
local lives = 3
--local score = 0
local died = false
 
local virussTable = {}
 
local motorcycle
local gameLoopTimer
local livesText

-- Set up display groups
local backGroup = display.newGroup()  -- Display group for the background image
local mainGroup = display.newGroup()  -- Display group for the virus
local uiGroup = display.newGroup()    -- Display group for UI objects like the score & lives

-- Load the background
local background = display.newImageRect( backGroup, "Asset/road.png", 300, 500 )
background.x = display.contentCenterX
background.y = display.contentCenterY

motorcycle = display.newImageRect( backGroup, "Asset/motor.png", 57, 75 )
motorcycle.x = display.contentCenterX
motorcycle.y = display.contentHeight - 70 -- Penempatan motorcycle
physics.addBody( motorcycle, { radius=15, isSensor=true } ) -- Radius motor terkena virus
motorcycle.myName = "motorcycle" -- untuk memberi nama objek motorcycle

-- Display lives and score
livesText = display.newText( uiGroup, "Lives: " .. lives, 80, 30, native.systemFont, 10 ) --penempatan letak lives dan fontstyle

-- Hide the status bar
display.setStatusBar( display.HiddenStatusBar ) -- untuk hidden status bar smartpone


local function updateText() -- untuk update nyawa
    livesText.text = "Lives: " .. lives
end


local function createVirus()
 
    local newVirus = display.newImageRect( mainGroup, objectVirus, math.random( 3 ), 30, 25 ) -- untuk menampilkan virus, ukuran virus dan saya random virus yang ditampilkan
    table.insert( virussTable, newVirus ) -- digunakan untuk menyimpan virus baru
    physics.addBody( newVirus, { radius=5, bounce=0.2 } ) -- untuk membuat radius virus dan saya atur 5 sebanding dengan besar virus, dan mengatur tingkat bounce virus saat bertabrakan
    newVirus.myName = "virus" -- untuk memberi nama objek virus
    
    newVirus.x = math.random( display.contentWidth )
    newVirus.y = -50 -- untuk memunculkan virus dari atas, dan saya atur -50 agar saat muncul tidak terlihat oleh player
    newVirus:setLinearVelocity( math.random( -40,40 ), math.random( 40,120 ) ) -- mengatur virus bergerak ke arah yang stabil

end



local function dragMotorcycle( event )
 
    local motorcycle = event.target
    local phase = event.phase
    
    if ( "began" == phase ) then
        -- Atur fokus sentuhan pada sepeda motor
        display.currentStage:setFocus( motorcycle )
        -- menyimpan posisi offset awal
        motorcycle.touchOffsetX = event.x - motorcycle.x
        
    elseif ( "moved" == phase ) then
        -- Pindahkan sepeda motor ke posisi baru
        motorcycle.x = event.x - motorcycle.touchOffsetX
        
    elseif ( "ended" == phase or "cancelled" == phase ) then
        -- Melepaskan fokus sentuh pada sepeda motor
        display.currentStage:setFocus( nil )
    end
    
    return true
end

motorcycle:addEventListener( "touch", dragMotorcycle )


local function gameLoop()
 
    -- Membuat virus baru
    createVirus()
    
    -- Menghapus virus setelah keluar dari screen
    for i = #virussTable, 1, -1 do
        local thisVirus = virussTable[i]
 
        if ( thisVirus.x < -100 or
             thisVirus.x > display.contentWidth + 100 or
             thisVirus.y < -100 or
             thisVirus.y > display.contentHeight + 100 )
        then
            display.remove( thisVirus )
            table.remove( virussTable, i )
        end
    end
end

gameLoopTimer = timer.performWithDelay( 700, gameLoop, 0 ) -- mengatur delay looping game selama 500 mili detik, termasuk memunculkan virus, semakin kecil delaynya semakin banyak virus yang keluar


local function restoreMotorcycle() -- mengembalikan motorcycle setelah tabrakan dengan virus
 
    motorcycle.isBodyActive = false
    motorcycle.x = display.contentCenterX
    motorcycle.y = display.contentHeight - 70
 
    transition.to( motorcycle, { alpha=1, time=4000,
        onComplete = function()
            motorcycle.isBodyActive = true --menghapus motorcycle dari simulasi fisika selama 4000 milidetik, dengan waktu selama itu motorcycle tidak akan mati saat ditabrak virus lagi
            died = false
        end
    } )
end


local function onCollision( event )
 
    if ( event.phase == "began" ) then
 
        local obj1 = event.object1
        local obj2 = event.object2
            
        if ( ( obj1.myName == "motorcycle" and obj2.myName == "virus" ) or
                ( obj1.myName == "virus" and obj2.myName == "motorcycle" ) )
        then
            if ( died == false ) then
                died = true
                
                -- Update lives
                lives = lives - 1
                livesText.text = "Lives: " .. lives
                
                if ( lives == 0 ) then -- jika lives samadengan 0 maka motorcycle akan hilang di screen
                    display.remove( motorcycle ) 
                else
                    motorcycle.alpha = 0 -- jika tidak maka maka akan memanggil function restoreMotorcycle denagn delay 1000 mili detik
                    timer.performWithDelay( 1000, restoreMotorcycle )
                end
            end
        end
    end
end

Runtime:addEventListener( "collision", onCollision )