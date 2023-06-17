local prefabs =
{
    "collapse_small",
}

local function Chair_TrySpawnShadeling(inst)
	TheWorld.components.ruinsshadelingspawner:TrySpawnShadeling(inst)
end

local function Chair_ClearNoShadeling(inst)
	inst.noshadelingtask = nil
end

local function Chair_OnEntityWake(inst)
	if inst.chairtask == nil and inst.noshadelingtask == nil then
		inst.chairtask = inst:DoTaskInTime(0, Chair_TrySpawnShadeling)
	end
end

local function Chair_OnEntitySleep(inst)
	if inst.chairtask ~= nil then
		inst.chairtask:Cancel()
		inst.chairtask = nil
	end
end

local function item(name, animated, sound, radius)
    local build = "ruins_"..name
    local assets =
    {
        Asset("ANIM", "anim/"..build..".zip"),
    }

    local function OnHammered(inst, worker)
        local fx = SpawnPrefab("collapse_small")
        fx.Transform:SetPosition(inst.Transform:GetWorldPosition())
        fx:SetMaterial(sound)
        inst.components.lootdropper:DropLoot()
        inst:Remove()
    end

    local function OnBuilt(inst)
        if animated then
            inst.AnimState:PlayAnimation("hit")
            inst.AnimState:PushAnimation("idle", false)
        end
        inst.SoundEmitter:PlaySound(sound == "rock" and "dontstarve/common/fixed_stonefurniture" or "dontstarve/common/repair_stonefurniture")
		if inst.OnEntityWake == Chair_OnEntityWake then
			inst.noshadelingtask = inst:DoTaskInTime(0, Chair_ClearNoShadeling)
		end
    end

    local function fn()
        local inst = CreateEntity()

        inst.entity:AddTransform()
        inst.entity:AddAnimState()
        inst.entity:AddSoundEmitter()
        inst.entity:AddNetwork()

        if radius > 0 then
            MakeObstaclePhysics(inst, radius)
        else
            MakeInventoryPhysics(inst)
        end

        inst.AnimState:SetBank(build)
        inst.AnimState:SetBuild(build)
        inst.AnimState:PlayAnimation("idle")
		if name == "chair" then
			inst.AnimState:SetFinalOffset(-1)
		end

        inst.entity:SetPristine()

        if not TheWorld.ismastersim then
            return inst
        end

        inst:AddComponent("inspectable")
        inst.components.inspectable.nameoverride = "relic"

        inst:AddComponent("workable")
        inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
        inst.components.workable:SetWorkLeft(1)
        inst.components.workable:SetOnFinishCallback(OnHammered)

        inst:AddComponent("lootdropper")

        inst:ListenForEvent("onbuilt", OnBuilt)

        MakeHauntableWork(inst)

		if name == "chair" then
			inst:AddComponent("sittable")

			if TheWorld.components.ruinsshadelingspawner ~= nil then
				inst.OnEntityWake = Chair_OnEntityWake
				inst.OnEntitySleep = Chair_OnEntitySleep
			end
		end

        return inst
    end

    return Prefab("ruinsrelic_"..name, fn, assets, prefabs)
end

-- These are the fake/replica versions the players can craft, see smashables.lua for ruins version
return item("plate", false, "pot", 0),
    item("bowl", false, "pot", .25),
    item("chair", true, "rock", .25),
    item("chipbowl", false, "pot", 0),
    item("vase", true, "pot", .25),
    item("table", true, "rock", .5),
    MakePlacer("ruinsrelic_plate_placer", "ruins_plate", "ruins_plate", "idle"),
    MakePlacer("ruinsrelic_bowl_placer", "ruins_bowl", "ruins_bowl", "idle"),
    MakePlacer("ruinsrelic_chair_placer", "ruins_chair", "ruins_chair", "idle"),
    MakePlacer("ruinsrelic_chipbowl_placer", "ruins_chipbowl", "ruins_chipbowl", "idle"),
    MakePlacer("ruinsrelic_vase_placer", "ruins_vase", "ruins_vase", "idle"),
    MakePlacer("ruinsrelic_table_placer", "ruins_table", "ruins_table", "idle")
