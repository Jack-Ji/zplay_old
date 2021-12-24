pub const c = @import("c.zig");
pub const worldCreate = c.cbtWorldCreate;
pub const worldDestroy = c.cbtWorldDestroy;
pub const worldSetGravity = c.cbtWorldSetGravity;
pub const worldGetGravity = c.cbtWorldGetGravity;
pub const worldStepSimulation = c.cbtWorldStepSimulation;
pub const worldAddBody = c.cbtWorldAddBody;
pub const worldAddConstraint = c.cbtWorldAddConstraint;
pub const worldRemoveBody = c.cbtWorldRemoveBody;
pub const worldRemoveConstraint = c.cbtWorldRemoveConstraint;
pub const worldGetNumBodies = c.cbtWorldGetNumBodies;
pub const worldGetNumConstraints = c.cbtWorldGetNumConstraints;
pub const worldGetBody = c.cbtWorldGetBody;
pub const worldGetConstraint = c.cbtWorldGetConstraint;
pub const rayTestClosest = c.cbtRayTestClosest;
pub const worldDebugSetCallbacks = c.cbtWorldDebugSetCallbacks;
pub const worldDebugDraw = c.cbtWorldDebugDraw;
pub const worldDebugDrawLine1 = c.cbtWorldDebugDrawLine1;
pub const worldDebugDrawLine2 = c.cbtWorldDebugDrawLine2;
pub const worldDebugDrawSphere = c.cbtWorldDebugDrawSphere;
pub const shapeAllocate = c.cbtShapeAllocate;
pub const shapeDeallocate = c.cbtShapeDeallocate;
pub const shapeDestroy = c.cbtShapeDestroy;
pub const shapeIsCreated = c.cbtShapeIsCreated;
pub const shapeGetType = c.cbtShapeGetType;
pub const shapeSetMargin = c.cbtShapeSetMargin;
pub const shapeGetMargin = c.cbtShapeGetMargin;
pub const shapeBoxCreate = c.cbtShapeBoxCreate;
pub const shapeBoxGetHalfExtentsWithoutMargin = c.cbtShapeBoxGetHalfExtentsWithoutMargin;
pub const shapeBoxGetHalfExtentsWithMargin = c.cbtShapeBoxGetHalfExtentsWithMargin;
pub const shapeSphereCreate = c.cbtShapeSphereCreate;
pub const shapeSphereSetUnscaledRadius = c.cbtShapeSphereSetUnscaledRadius;
pub const shapeSphereGetRadius = c.cbtShapeSphereGetRadius;
pub const shapeCapsuleCreate = c.cbtShapeCapsuleCreate;
pub const shapeCapsuleGetUpAxis = c.cbtShapeCapsuleGetUpAxis;
pub const shapeCapsuleGetHalfHeight = c.cbtShapeCapsuleGetHalfHeight;
pub const shapeCapsuleGetRadius = c.cbtShapeCapsuleGetRadius;
pub const shapeCylinderCreate = c.cbtShapeCylinderCreate;
pub const shapeCylinderGetHalfExtentsWithoutMargin = c.cbtShapeCylinderGetHalfExtentsWithoutMargin;
pub const shapeCylinderGetHalfExtentsWithMargin = c.cbtShapeCylinderGetHalfExtentsWithMargin;
pub const shapeCylinderGetUpAxis = c.cbtShapeCylinderGetUpAxis;
pub const shapeConeCreate = c.cbtShapeConeCreate;
pub const shapeConeGetRadius = c.cbtShapeConeGetRadius;
pub const shapeConeGetHeight = c.cbtShapeConeGetHeight;
pub const shapeConeGetUpAxis = c.cbtShapeConeGetUpAxis;
pub const shapeCompoundCreate = c.cbtShapeCompoundCreate;
pub const shapeCompoundAddChild = c.cbtShapeCompoundAddChild;
pub const shapeCompoundRemoveChild = c.cbtShapeCompoundRemoveChild;
pub const shapeCompoundRemoveChildByIndex = c.cbtShapeCompoundRemoveChildByIndex;
pub const shapeCompoundGetNumChilds = c.cbtShapeCompoundGetNumChilds;
pub const shapeCompoundGetChild = c.cbtShapeCompoundGetChild;
pub const shapeCompoundGetChildTransform = c.cbtShapeCompoundGetChildTransform;
pub const shapeTriMeshCreateBegin = c.cbtShapeTriMeshCreateBegin;
pub const shapeTriMeshCreateEnd = c.cbtShapeTriMeshCreateEnd;
pub const shapeTriMeshDestroy = c.cbtShapeTriMeshDestroy;
pub const shapeTriMeshAddIndexVertexArray = c.cbtShapeTriMeshAddIndexVertexArray;
pub const shapeIsPolyhedral = c.cbtShapeIsPolyhedral;
pub const shapeIsConvex2d = c.cbtShapeIsConvex2d;
pub const shapeIsConvex = c.cbtShapeIsConvex;
pub const shapeIsNonMoving = c.cbtShapeIsNonMoving;
pub const shapeIsConcave = c.cbtShapeIsConcave;
pub const shapeIsCompound = c.cbtShapeIsCompound;
pub const shapeCalculateLocalInertia = c.cbtShapeCalculateLocalInertia;
pub const shapeSetUserPointer = c.cbtShapeSetUserPointer;
pub const shapeGetUserPointer = c.cbtShapeGetUserPointer;
pub const shapeSetUserIndex = c.cbtShapeSetUserIndex;
pub const shapeGetUserIndex = c.cbtShapeGetUserIndex;
pub const bodyAllocate = c.cbtBodyAllocate;
pub const bodyAllocateBatch = c.cbtBodyAllocateBatch;
pub const bodyDeallocate = c.cbtBodyDeallocate;
pub const bodyDeallocateBatch = c.cbtBodyDeallocateBatch;
pub const bodyCreate = c.cbtBodyCreate;
pub const bodyDestroy = c.cbtBodyDestroy;
pub const bodyIsCreated = c.cbtBodyIsCreated;
pub const bodySetShape = c.cbtBodySetShape;
pub const bodyGetShape = c.cbtBodyGetShape;
pub const bodySetRestitution = c.cbtBodySetRestitution;
pub const bodySetFriction = c.cbtBodySetFriction;
pub const bodySetRollingFriction = c.cbtBodySetRollingFriction;
pub const bodySetSpinningFriction = c.cbtBodySetSpinningFriction;
pub const bodySetAnisotropicFriction = c.cbtBodySetAnisotropicFriction;
pub const bodySetContactStiffnessAndDamping = c.cbtBodySetContactStiffnessAndDamping;
pub const bodySetMassProps = c.cbtBodySetMassProps;
pub const bodySetDamping = c.cbtBodySetDamping;
pub const bodySetLinearVelocity = c.cbtBodySetLinearVelocity;
pub const bodySetAngularVelocity = c.cbtBodySetAngularVelocity;
pub const bodySetLinearFactor = c.cbtBodySetLinearFactor;
pub const bodySetAngularFactor = c.cbtBodySetAngularFactor;
pub const bodySetGravity = c.cbtBodySetGravity;
pub const bodyGetGravity = c.cbtBodyGetGravity;
pub const bodyGetNumConstraints = c.cbtBodyGetNumConstraints;
pub const bodyGetConstraint = c.cbtBodyGetConstraint;
pub const bodyApplyCentralForce = c.cbtBodyApplyCentralForce;
pub const bodyApplyCentralImpulse = c.cbtBodyApplyCentralImpulse;
pub const bodyApplyForce = c.cbtBodyApplyForce;
pub const bodyApplyImpulse = c.cbtBodyApplyImpulse;
pub const bodyApplyTorque = c.cbtBodyApplyTorque;
pub const bodyApplyTorqueImpulse = c.cbtBodyApplyTorqueImpulse;
pub const bodyGetRestitution = c.cbtBodyGetRestitution;
pub const bodyGetFriction = c.cbtBodyGetFriction;
pub const bodyGetRollingFriction = c.cbtBodyGetRollingFriction;
pub const bodyGetSpinningFriction = c.cbtBodyGetSpinningFriction;
pub const bodyGetAnisotropicFriction = c.cbtBodyGetAnisotropicFriction;
pub const bodyGetContactStiffness = c.cbtBodyGetContactStiffness;
pub const bodyGetContactDamping = c.cbtBodyGetContactDamping;
pub const bodyGetMass = c.cbtBodyGetMass;
pub const bodyGetLinearDamping = c.cbtBodyGetLinearDamping;
pub const bodyGetAngularDamping = c.cbtBodyGetAngularDamping;
pub const bodyGetLinearVelocity = c.cbtBodyGetLinearVelocity;
pub const bodyGetAngularVelocity = c.cbtBodyGetAngularVelocity;
pub const bodyGetTotalForce = c.cbtBodyGetTotalForce;
pub const bodyGetTotalTorque = c.cbtBodyGetTotalTorque;
pub const bodyIsStatic = c.cbtBodyIsStatic;
pub const bodyIsKinematic = c.cbtBodyIsKinematic;
pub const bodyIsStaticOrKinematic = c.cbtBodyIsStaticOrKinematic;
pub const bodyGetDeactivationTime = c.cbtBodyGetDeactivationTime;
pub const bodySetDeactivationTime = c.cbtBodySetDeactivationTime;
pub const bodyGetActivationState = c.cbtBodyGetActivationState;
pub const bodySetActivationState = c.cbtBodySetActivationState;
pub const bodyForceActivationState = c.cbtBodyForceActivationState;
pub const bodyIsActive = c.cbtBodyIsActive;
pub const bodyIsInWorld = c.cbtBodyIsInWorld;
pub const bodySetUserPointer = c.cbtBodySetUserPointer;
pub const bodyGetUserPointer = c.cbtBodyGetUserPointer;
pub const bodySetUserIndex = c.cbtBodySetUserIndex;
pub const bodyGetUserIndex = c.cbtBodyGetUserIndex;
pub const bodySetCenterOfMassTransform = c.cbtBodySetCenterOfMassTransform;
pub const bodyGetCenterOfMassTransform = c.cbtBodyGetCenterOfMassTransform;
pub const bodyGetCenterOfMassPosition = c.cbtBodyGetCenterOfMassPosition;
pub const bodyGetInvCenterOfMassTransform = c.cbtBodyGetInvCenterOfMassTransform;
pub const bodyGetGraphicsWorldTransform = c.cbtBodyGetGraphicsWorldTransform;
pub const conGetFixedBody = c.cbtConGetFixedBody;
pub const conAllocate = c.cbtConAllocate;
pub const conDeallocate = c.cbtConDeallocate;
pub const conDestroy = c.cbtConDestroy;
pub const conIsCreated = c.cbtConIsCreated;
pub const conGetType = c.cbtConGetType;
pub const conSetParam = c.cbtConSetParam;
pub const conGetParam = c.cbtConGetParam;
pub const conSetEnabled = c.cbtConSetEnabled;
pub const conIsEnabled = c.cbtConIsEnabled;
pub const conGetBodyA = c.cbtConGetBodyA;
pub const conGetBodyB = c.cbtConGetBodyB;
pub const conSetBreakingImpulseThreshold = c.cbtConSetBreakingImpulseThreshold;
pub const conGetBreakingImpulseThreshold = c.cbtConGetBreakingImpulseThreshold;
pub const conSetDebugDrawSize = c.cbtConSetDebugDrawSize;
pub const conGetDebugDrawSize = c.cbtConGetDebugDrawSize;
pub const conPoint2PointCreate1 = c.cbtConPoint2PointCreate1;
pub const conPoint2PointCreate2 = c.cbtConPoint2PointCreate2;
pub const conPoint2PointSetPivotA = c.cbtConPoint2PointSetPivotA;
pub const conPoint2PointSetPivotB = c.cbtConPoint2PointSetPivotB;
pub const conPoint2PointSetTau = c.cbtConPoint2PointSetTau;
pub const conPoint2PointSetDamping = c.cbtConPoint2PointSetDamping;
pub const conPoint2PointSetImpulseClamp = c.cbtConPoint2PointSetImpulseClamp;
pub const conPoint2PointGetPivotA = c.cbtConPoint2PointGetPivotA;
pub const conPoint2PointGetPivotB = c.cbtConPoint2PointGetPivotB;
pub const conHingeCreate1 = c.cbtConHingeCreate1;
pub const conHingeCreate2 = c.cbtConHingeCreate2;
pub const conHingeCreate3 = c.cbtConHingeCreate3;
pub const conHingeSetAngularOnly = c.cbtConHingeSetAngularOnly;
pub const conHingeEnableAngularMotor = c.cbtConHingeEnableAngularMotor;
pub const conHingeSetLimit = c.cbtConHingeSetLimit;
pub const conGearCreate = c.cbtConGearCreate;
pub const conGearSetAxisA = c.cbtConGearSetAxisA;
pub const conGearSetAxisB = c.cbtConGearSetAxisB;
pub const conGearSetRatio = c.cbtConGearSetRatio;
pub const conGearGetAxisA = c.cbtConGearGetAxisA;
pub const conGearGetAxisB = c.cbtConGearGetAxisB;
pub const conGearGetRatio = c.cbtConGearGetRatio;
pub const conSliderCreate1 = c.cbtConSliderCreate1;
pub const conSliderCreate2 = c.cbtConSliderCreate2;
pub const conSliderSetLinearLowerLimit = c.cbtConSliderSetLinearLowerLimit;
pub const conSliderSetLinearUpperLimit = c.cbtConSliderSetLinearUpperLimit;
pub const conSliderGetLinearLowerLimit = c.cbtConSliderGetLinearLowerLimit;
pub const conSliderGetLinearUpperLimit = c.cbtConSliderGetLinearUpperLimit;
pub const conSliderSetAngularLowerLimit = c.cbtConSliderSetAngularLowerLimit;
pub const conSliderSetAngularUpperLimit = c.cbtConSliderSetAngularUpperLimit;
pub const conSliderGetAngularLowerLimit = c.cbtConSliderGetAngularLowerLimit;
pub const conSliderGetAngularUpperLimit = c.cbtConSliderGetAngularUpperLimit;
pub const conSliderEnableLinearMotor = c.cbtConSliderEnableLinearMotor;
pub const conSliderEnableAngularMotor = c.cbtConSliderEnableAngularMotor;
pub const conSliderIsLinearMotorEnabled = c.cbtConSliderIsLinearMotorEnabled;
pub const conSliderIsAngularMotorEnabled = c.cbtConSliderIsAngularMotorEnabled;
pub const conSliderGetAngularMotor = c.cbtConSliderGetAngularMotor;
pub const conSliderGetLinearPosition = c.cbtConSliderGetLinearPosition;
pub const conSliderGetAngularPosition = c.cbtConSliderGetAngularPosition;
pub const conD6Spring2Create1 = c.cbtConD6Spring2Create1;
pub const conD6Spring2Create2 = c.cbtConD6Spring2Create2;
pub const conD6Spring2SetLinearLowerLimit = c.cbtConD6Spring2SetLinearLowerLimit;
pub const conD6Spring2SetLinearUpperLimit = c.cbtConD6Spring2SetLinearUpperLimit;
pub const conD6Spring2GetLinearLowerLimit = c.cbtConD6Spring2GetLinearLowerLimit;
pub const conD6Spring2GetLinearUpperLimit = c.cbtConD6Spring2GetLinearUpperLimit;
pub const conD6Spring2SetAngularLowerLimit = c.cbtConD6Spring2SetAngularLowerLimit;
pub const conD6Spring2SetAngularUpperLimit = c.cbtConD6Spring2SetAngularUpperLimit;
pub const conD6Spring2GetAngularLowerLimit = c.cbtConD6Spring2GetAngularLowerLimit;
pub const conD6Spring2GetAngularUpperLimit = c.cbtConD6Spring2GetAngularUpperLimit;
pub const conConeTwistCreate1 = c.cbtConConeTwistCreate1;
pub const conConeTwistCreate2 = c.cbtConConeTwistCreate2;
pub const conConeTwistSetLimit = c.cbtConConeTwistSetLimit;
