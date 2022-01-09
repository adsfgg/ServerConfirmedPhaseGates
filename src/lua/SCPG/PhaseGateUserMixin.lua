-- Remove the vanilla implementation of PhaseGateUserMixin.OnProcessMove
PhaseGateUserMixin.OnProcessMove = nil

if Server then
    -- Only process the move server side, this will incur a slight delay on the client due to the poor tickrate
    function PhaseGateUserMixin:OnProcessMove(input)
        if self:GetCanPhase() then
            for _, phaseGate in ipairs(GetEntitiesForTeamWithinRange("PhaseGate", self:GetTeamNumber(), self:GetOrigin(), 0.5)) do
                if phaseGate:GetIsDeployed() and GetIsUnitActive(phaseGate) and phaseGate:Phase(self) then
                    -- If we can found a phasegate we can phase through, inform the server
                    self.timeOfLastPhase = Shared.GetTime()
                    local id = self:GetId()
                    Server.SendNetworkMessage(self:GetClient(), "OnPhase", { phaseGateId = phaseGate:GetId(), phasedEntityId = id or Entity.invalidId }, true)
                    return
                end
            end
        end

        self.phasedLastUpdate = false
    end
end

local kOnPhase =
{
    phaseGateId = "entityid",
    phasedEntityId = "entityid"
}
Shared.RegisterNetworkMessage("OnPhase", kOnPhase)

if Client then
    local function OnMessagePhase(message)
        PROFILE("PhaseGateUserMixin:OnMessagePhase")
        -- TODO: Is there a better way to do this?
        local phaseGate = Shared.GetEntity(message.phaseGateId)
        local phasedEnt = Shared.GetEntity(message.phasedEntityId)

        -- Need to keep this var updated so that client side effects work correctly
        phasedEnt.timeOfLastPhaseClient = Shared.GetTime()

        phaseGate:Phase(phasedEnt)
        local viewAngles = phasedEnt:GetViewAngles()

        -- Update view angles
        Client.SetYaw(viewAngles.yaw)
        Client.SetPitch(viewAngles.pitch)
    end
    Client.HookNetworkMessage("OnPhase", OnMessagePhase)
end
