pub const c = @import("c.zig");

/// types
pub const Float = c.cpFloat;
pub const HashValue = c.cpHashValue;
pub const CollisionID = c.cpCollisionID;
pub const Cpbool = c.cpBool;
pub const DataPointer = c.cpDataPointer;
pub const CollisionType = c.cpCollisionType;
pub const Group = c.cpGroup;
pub const Bitmask = c.cpBitmask;
pub const Timestamp = c.cpTimestamp;
pub const Vect = c.cpVect;
pub const Transform = c.cpTransform;
pub const Mat2x2 = c.cpMat2x2;
pub const Array = c.cpArray;
pub const HashSet = c.cpHashSet;
pub const Body = c.cpBody;
pub const Shape = c.cpShape;
pub const CircleShape = c.cpCircleShape;
pub const SegmentShape = c.cpSegmentShape;
pub const PolyShape = c.cpPolyShape;
pub const Constraint = c.cpConstraint;
pub const PinJoint = c.cpPinJoint;
pub const SlideJoint = c.cpSlideJoint;
pub const PivotJoint = c.cpPivotJoint;
pub const GrooveJoint = c.cpGrooveJoint;
pub const DampedSpring = c.cpDampedSpring;
pub const DampedRotarySpring = c.cpDampedRotarySpring;
pub const RotaryLimitJoint = c.cpRotaryLimitJoint;
pub const RatchetJoint = c.cpRatchetJoint;
pub const GearJoint = c.cpGearJoint;
pub const SimpleMotorJoint = c.cpSimpleMotorJoint;
pub const Arbiter = c.cpArbiter;
pub const Space = c.cpSpace;
pub const CollisionBeginFunc = c.cpCollisionBeginFunc;
pub const CollisionPreSolveFunc = c.cpCollisionPreSolveFunc;
pub const CollisionPostSolveFunc = c.cpCollisionPostSolveFunc;
pub const CollisionSeparateFunc = c.cpCollisionSeparateFunc;
pub const CollisionHandler = c.cpCollisionHandler;
pub const ContactPointSet = c.cpContactPointSet;
pub const Vzero = c.cpvzero;
pub const BB = c.cpBB;
pub const TransformIdentity = c.cpTransformIdentity;
pub const SpatialIndexBBFunc = c.cpSpatialIndexBBFunc;
pub const SpatialIndexIteratorFunc = c.cpSpatialIndexIteratorFunc;
pub const SpatialIndexQueryFunc = c.cpSpatialIndexQueryFunc;
pub const SpatialIndexSegmentQueryFunc = c.cpSpatialIndexSegmentQueryFunc;
pub const SpatialIndexClass = c.cpSpatialIndexClass;
pub const SpatialIndex = c.cpSpatialIndex;
pub const SpatialIndexDestroyImpl = c.cpSpatialIndexDestroyImpl;
pub const SpatialIndexCountImpl = c.cpSpatialIndexCountImpl;
pub const SpatialIndexEachImpl = c.cpSpatialIndexEachImpl;
pub const SpatialIndexContainsImpl = c.cpSpatialIndexContainsImpl;
pub const SpatialIndexInsertImpl = c.cpSpatialIndexInsertImpl;
pub const SpatialIndexRemoveImpl = c.cpSpatialIndexRemoveImpl;
pub const SpatialIndexReindexImpl = c.cpSpatialIndexReindexImpl;
pub const SpatialIndexReindexObjectImpl = c.cpSpatialIndexReindexObjectImpl;
pub const SpatialIndexReindexQueryImpl = c.cpSpatialIndexReindexQueryImpl;
pub const SpatialIndexQueryImpl = c.cpSpatialIndexQueryImpl;
pub const SpatialIndexSegmentQueryImpl = c.cpSpatialIndexSegmentQueryImpl;
pub const SpaceHash = c.cpSpaceHash;
pub const BBTree = c.cpBBTree;
pub const BBTreeVelocityFunc = c.cpBBTreeVelocityFunc;
pub const Sweep1D = c.cpSweep1D;
pub const BodyType = c.cpBodyType;
pub const BodyVelocityFunc = c.cpBodyVelocityFunc;
pub const BodyPositionFunc = c.cpBodyPositionFunc;
pub const BodyShapeIteratorFunc = c.cpBodyShapeIteratorFunc;
pub const BodyConstraintIteratorFunc = c.cpBodyConstraintIteratorFunc;
pub const BodyArbiterIteratorFunc = c.cpBodyArbiterIteratorFunc;
pub const PointQueryInfo = c.cpPointQueryInfo;
pub const SegmentQueryInfo = c.cpSegmentQueryInfo;
pub const ShapeFilter = c.cpShapeFilter;
pub const ConstraintPreSolveFunc = c.cpConstraintPreSolveFunc;
pub const ConstraintPostSolveFunc = c.cpConstraintPostSolveFunc;
pub const DampedSpringForceFunc = c.cpDampedSpringForceFunc;
pub const DampedRotarySpringTorqueFunc = c.cpDampedRotarySpringTorqueFunc;
pub const SimpleMotor = c.cpSimpleMotor;
pub const PostStepFunc = c.cpPostStepFunc;
pub const SpacePointQueryFunc = c.cpSpacePointQueryFunc;
pub const SpaceSegmentQueryFunc = c.cpSpaceSegmentQueryFunc;
pub const SpaceBBQueryFunc = c.cpSpaceBBQueryFunc;
pub const SpaceShapeQueryFunc = c.cpSpaceShapeQueryFunc;
pub const SpaceBodyIteratorFunc = c.cpSpaceBodyIteratorFunc;
pub const SpaceShapeIteratorFunc = c.cpSpaceShapeIteratorFunc;
pub const SpaceConstraintIteratorFunc = c.cpSpaceConstraintIteratorFunc;
pub const SpaceDebugColor = c.cpSpaceDebugColor;
pub const SpaceDebugDrawCircleImpl = c.cpSpaceDebugDrawCircleImpl;
pub const SpaceDebugDrawSegmentImpl = c.cpSpaceDebugDrawSegmentImpl;
pub const SpaceDebugDrawFatSegmentImpl = c.cpSpaceDebugDrawFatSegmentImpl;
pub const SpaceDebugDrawPolygonImpl = c.cpSpaceDebugDrawPolygonImpl;
pub const SpaceDebugDrawDotImpl = c.cpSpaceDebugDrawDotImpl;
pub const SpaceDebugDrawColorForShapeImpl = c.cpSpaceDebugDrawColorForShapeImpl;
pub const SpaceDebugDrawFlags = c.cpSpaceDebugDrawFlags;
pub const SpaceDebugDrawOptions = c.cpSpaceDebugDrawOptions;

/// functions
pub const message = c.cpMessage;
pub const fmax = c.cpfmax;
pub const fmin = c.cpfmin;
pub const fabs = c.cpfabs;
pub const fclamp = c.cpfclamp;
pub const fclamp01 = c.cpfclamp01;
pub const flerp = c.cpflerp;
pub const flerpconst = c.cpflerpconst;
pub const v = c.cpv;
pub const veql = c.cpveql;
pub const vadd = c.cpvadd;
pub const vsub = c.cpvsub;
pub const vneg = c.cpvneg;
pub const vmult = c.cpvmult;
pub const vdot = c.cpvdot;
pub const vcross = c.cpvcross;
pub const vperp = c.cpvperp;
pub const vrperp = c.cpvrperp;
pub const vproject = c.cpvproject;
pub const vforangle = c.cpvforangle;
pub const vtoangle = c.cpvtoangle;
pub const vrotate = c.cpvrotate;
pub const vunrotate = c.cpvunrotate;
pub const vlengthsq = c.cpvlengthsq;
pub const vlength = c.cpvlength;
pub const vlerp = c.cpvlerp;
pub const vnormalize = c.cpvnormalize;
pub const vslerp = c.cpvslerp;
pub const vslerpconst = c.cpvslerpconst;
pub const vclamp = c.cpvclamp;
pub const vlerpconst = c.cpvlerpconst;
pub const vdist = c.cpvdist;
pub const vdistsq = c.cpvdistsq;
pub const vnear = c.cpvnear;
pub const mat2x2New = c.cpMat2x2New;
pub const mat2x2Transform = c.cpMat2x2Transform;
pub const bBNew = c.cpBBNew;
pub const bBNewForExtents = c.cpBBNewForExtents;
pub const bBNewForCircle = c.cpBBNewForCircle;
pub const bBIntersects = c.cpBBIntersects;
pub const bBContainsBB = c.cpBBContainsBB;
pub const bBContainsVect = c.cpBBContainsVect;
pub const bBMerge = c.cpBBMerge;
pub const bBExpand = c.cpBBExpand;
pub const bBCenter = c.cpBBCenter;
pub const bBArea = c.cpBBArea;
pub const bBMergedArea = c.cpBBMergedArea;
pub const bBSegmentQuery = c.cpBBSegmentQuery;
pub const bBIntersectsSegment = c.cpBBIntersectsSegment;
pub const bBClampVect = c.cpBBClampVect;
pub const bBWrapVect = c.cpBBWrapVect;
pub const bBOffset = c.cpBBOffset;
pub const transformNew = c.cpTransformNew;
pub const transformNewTranspose = c.cpTransformNewTranspose;
pub const transformInverse = c.cpTransformInverse;
pub const transformMult = c.cpTransformMult;
pub const transformPoint = c.cpTransformPoint;
pub const transformVect = c.cpTransformVect;
pub const transformbBB = c.cpTransformbBB;
pub const transformTranslate = c.cpTransformTranslate;
pub const transformScale = c.cpTransformScale;
pub const transformRotate = c.cpTransformRotate;
pub const transformRigid = c.cpTransformRigid;
pub const transformRigidInverse = c.cpTransformRigidInverse;
pub const transformWrap = c.cpTransformWrap;
pub const transformWrapInverse = c.cpTransformWrapInverse;
pub const transformOrtho = c.cpTransformOrtho;
pub const transformBoneScale = c.cpTransformBoneScale;
pub const transformAxialScale = c.cpTransformAxialScale;
pub const spaceHashAlloc = c.cpSpaceHashAlloc;
pub const spaceHashInit = c.cpSpaceHashInit;
pub const spaceHashNew = c.cpSpaceHashNew;
pub const spaceHashResize = c.cpSpaceHashResize;
pub const bBTreeAlloc = c.cpBBTreeAlloc;
pub const bBTreeInit = c.cpBBTreeInit;
pub const bBTreeNew = c.cpBBTreeNew;
pub const bBTreeOptimize = c.cpBBTreeOptimize;
pub const bBTreeSetVelocityFunc = c.cpBBTreeSetVelocityFunc;
pub const sweep1DAlloc = c.cpSweep1DAlloc;
pub const sweep1DInit = c.cpSweep1DInit;
pub const sweep1DNew = c.cpSweep1DNew;
pub const spatialIndexFree = c.cpSpatialIndexFree;
pub const spatialIndexCollideStatic = c.cpSpatialIndexCollideStatic;
pub const spatialIndexDestroy = c.cpSpatialIndexDestroy;
pub const spatialIndexCount = c.cpSpatialIndexCount;
pub const spatialIndexEach = c.cpSpatialIndexEach;
pub const spatialIndexContains = c.cpSpatialIndexContains;
pub const spatialIndexInsert = c.cpSpatialIndexInsert;
pub const spatialIndexRemove = c.cpSpatialIndexRemove;
pub const spatialIndexReindex = c.cpSpatialIndexReindex;
pub const spatialIndexReindexObject = c.cpSpatialIndexReindexObject;
pub const spatialIndexQuery = c.cpSpatialIndexQuery;
pub const spatialIndexSegmentQuery = c.cpSpatialIndexSegmentQuery;
pub const spatialIndexReindexQuery = c.cpSpatialIndexReindexQuery;
pub const arbiterGetRestitution = c.cpArbiterGetRestitution;
pub const arbiterSetRestitution = c.cpArbiterSetRestitution;
pub const arbiterGetFriction = c.cpArbiterGetFriction;
pub const arbiterSetFriction = c.cpArbiterSetFriction;
pub const arbiterGetSurfaceVelocity = c.cpArbiterGetSurfaceVelocity;
pub const arbiterSetSurfaceVelocity = c.cpArbiterSetSurfaceVelocity;
pub const arbiterGetUserData = c.cpArbiterGetUserData;
pub const arbiterSetUserData = c.cpArbiterSetUserData;
pub const arbiterTotalImpulse = c.cpArbiterTotalImpulse;
pub const arbiterTotalKE = c.cpArbiterTotalKE;
pub const arbiterIgnore = c.cpArbiterIgnore;
pub const arbiterGetShapes = c.cpArbiterGetShapes;
pub const arbiterGetBodies = c.cpArbiterGetBodies;
pub const arbiterGetContactPointSet = c.cpArbiterGetContactPointSet;
pub const arbiterSetContactPointSet = c.cpArbiterSetContactPointSet;
pub const arbiterIsFirstContact = c.cpArbiterIsFirstContact;
pub const arbiterIsRemoval = c.cpArbiterIsRemoval;
pub const arbiterGetCount = c.cpArbiterGetCount;
pub const arbiterGetNormal = c.cpArbiterGetNormal;
pub const arbiterGetPointA = c.cpArbiterGetPointA;
pub const arbiterGetPointB = c.cpArbiterGetPointB;
pub const arbiterGetDepth = c.cpArbiterGetDepth;
pub const arbiterCallWildcardBeginA = c.cpArbiterCallWildcardBeginA;
pub const arbiterCallWildcardBeginB = c.cpArbiterCallWildcardBeginB;
pub const arbiterCallWildcardPreSolveA = c.cpArbiterCallWildcardPreSolveA;
pub const arbiterCallWildcardPreSolveB = c.cpArbiterCallWildcardPreSolveB;
pub const arbiterCallWildcardPostSolveA = c.cpArbiterCallWildcardPostSolveA;
pub const arbiterCallWildcardPostSolveB = c.cpArbiterCallWildcardPostSolveB;
pub const arbiterCallWildcardSeparateA = c.cpArbiterCallWildcardSeparateA;
pub const arbiterCallWildcardSeparateB = c.cpArbiterCallWildcardSeparateB;
pub const bodyAlloc = c.cpBodyAlloc;
pub const bodyInit = c.cpBodyInit;
pub const bodyNew = c.cpBodyNew;
pub const bodyNewKinematic = c.cpBodyNewKinematic;
pub const bodyNewStatic = c.cpBodyNewStatic;
pub const bodyDestroy = c.cpBodyDestroy;
pub const bodyFree = c.cpBodyFree;
pub const bodyActivate = c.cpBodyActivate;
pub const bodyActivateStatic = c.cpBodyActivateStatic;
pub const bodySleep = c.cpBodySleep;
pub const bodySleepWithGroup = c.cpBodySleepWithGroup;
pub const bodyIsSleeping = c.cpBodyIsSleeping;
pub const bodyGetType = c.cpBodyGetType;
pub const bodySetType = c.cpBodySetType;
pub const bodyGetSpace = c.cpBodyGetSpace;
pub const bodyGetMass = c.cpBodyGetMass;
pub const bodySetMass = c.cpBodySetMass;
pub const bodyGetMoment = c.cpBodyGetMoment;
pub const bodySetMoment = c.cpBodySetMoment;
pub const bodyGetPosition = c.cpBodyGetPosition;
pub const bodySetPosition = c.cpBodySetPosition;
pub const bodyGetCenterOfGravity = c.cpBodyGetCenterOfGravity;
pub const bodySetCenterOfGravity = c.cpBodySetCenterOfGravity;
pub const bodyGetVelocity = c.cpBodyGetVelocity;
pub const bodySetVelocity = c.cpBodySetVelocity;
pub const bodyGetForce = c.cpBodyGetForce;
pub const bodySetForce = c.cpBodySetForce;
pub const bodyGetAngle = c.cpBodyGetAngle;
pub const bodySetAngle = c.cpBodySetAngle;
pub const bodyGetAngularVelocity = c.cpBodyGetAngularVelocity;
pub const bodySetAngularVelocity = c.cpBodySetAngularVelocity;
pub const bodyGetTorque = c.cpBodyGetTorque;
pub const bodySetTorque = c.cpBodySetTorque;
pub const bodyGetRotation = c.cpBodyGetRotation;
pub const bodyGetUserData = c.cpBodyGetUserData;
pub const bodySetUserData = c.cpBodySetUserData;
pub const bodySetVelocityUpdateFunc = c.cpBodySetVelocityUpdateFunc;
pub const bodySetPositionUpdateFunc = c.cpBodySetPositionUpdateFunc;
pub const bodyUpdateVelocity = c.cpBodyUpdateVelocity;
pub const bodyUpdatePosition = c.cpBodyUpdatePosition;
pub const bodyLocalToWorld = c.cpBodyLocalToWorld;
pub const bodyWorldToLocal = c.cpBodyWorldToLocal;
pub const bodyApplyForceAtWorldPoint = c.cpBodyApplyForceAtWorldPoint;
pub const bodyApplyForceAtLocalPoint = c.cpBodyApplyForceAtLocalPoint;
pub const bodyApplyImpulseAtWorldPoint = c.cpBodyApplyImpulseAtWorldPoint;
pub const bodyApplyImpulseAtLocalPoint = c.cpBodyApplyImpulseAtLocalPoint;
pub const bodyGetVelocityAtWorldPoint = c.cpBodyGetVelocityAtWorldPoint;
pub const bodyGetVelocityAtLocalPoint = c.cpBodyGetVelocityAtLocalPoint;
pub const bodyKineticEnergy = c.cpBodyKineticEnergy;
pub const bodyEachShape = c.cpBodyEachShape;
pub const bodyEachConstraint = c.cpBodyEachConstraint;
pub const bodyEachArbiter = c.cpBodyEachArbiter;
pub const shapeFilterNew = c.cpShapeFilterNew;
pub const shapeDestroy = c.cpShapeDestroy;
pub const shapeFree = c.cpShapeFree;
pub const shapeCacheBB = c.cpShapeCacheBB;
pub const shapeUpdate = c.cpShapeUpdate;
pub const shapePointQuery = c.cpShapePointQuery;
pub const shapeSegmentQuery = c.cpShapeSegmentQuery;
pub const shapesCollide = c.cpShapesCollide;
pub const shapeGetSpace = c.cpShapeGetSpace;
pub const shapeGetBody = c.cpShapeGetBody;
pub const shapeSetBody = c.cpShapeSetBody;
pub const shapeGetMass = c.cpShapeGetMass;
pub const shapeSetMass = c.cpShapeSetMass;
pub const shapeGetDensity = c.cpShapeGetDensity;
pub const shapeSetDensity = c.cpShapeSetDensity;
pub const shapeGetMoment = c.cpShapeGetMoment;
pub const shapeGetArea = c.cpShapeGetArea;
pub const shapeGetCenterOfGravity = c.cpShapeGetCenterOfGravity;
pub const shapeGetBB = c.cpShapeGetBB;
pub const shapeGetSensor = c.cpShapeGetSensor;
pub const shapeSetSensor = c.cpShapeSetSensor;
pub const shapeGetElasticity = c.cpShapeGetElasticity;
pub const shapeSetElasticity = c.cpShapeSetElasticity;
pub const shapeGetFriction = c.cpShapeGetFriction;
pub const shapeSetFriction = c.cpShapeSetFriction;
pub const shapeGetSurfaceVelocity = c.cpShapeGetSurfaceVelocity;
pub const shapeSetSurfaceVelocity = c.cpShapeSetSurfaceVelocity;
pub const shapeGetUserData = c.cpShapeGetUserData;
pub const shapeSetUserData = c.cpShapeSetUserData;
pub const shapeGetCollisionType = c.cpShapeGetCollisionType;
pub const shapeSetCollisionType = c.cpShapeSetCollisionType;
pub const shapeGetFilter = c.cpShapeGetFilter;
pub const shapeSetFilter = c.cpShapeSetFilter;
pub const circleShapeAlloc = c.cpCircleShapeAlloc;
pub const circleShapeInit = c.cpCircleShapeInit;
pub const circleShapeNew = c.cpCircleShapeNew;
pub const circleShapeGetOffset = c.cpCircleShapeGetOffset;
pub const circleShapeGetRadius = c.cpCircleShapeGetRadius;
pub const segmentShapeAlloc = c.cpSegmentShapeAlloc;
pub const segmentShapeInit = c.cpSegmentShapeInit;
pub const segmentShapeNew = c.cpSegmentShapeNew;
pub const segmentShapeSetNeighbors = c.cpSegmentShapeSetNeighbors;
pub const segmentShapeGetA = c.cpSegmentShapeGetA;
pub const segmentShapeGetB = c.cpSegmentShapeGetB;
pub const segmentShapeGetNormal = c.cpSegmentShapeGetNormal;
pub const segmentShapeGetRadius = c.cpSegmentShapeGetRadius;
pub const polyShapeAlloc = c.cpPolyShapeAlloc;
pub const polyShapeInit = c.cpPolyShapeInit;
pub const polyShapeInitRaw = c.cpPolyShapeInitRaw;
pub const polyShapeNew = c.cpPolyShapeNew;
pub const polyShapeNewRaw = c.cpPolyShapeNewRaw;
pub const boxShapeInit = c.cpBoxShapeInit;
pub const boxShapeInit2 = c.cpBoxShapeInit2;
pub const boxShapeNew = c.cpBoxShapeNew;
pub const boxShapeNew2 = c.cpBoxShapeNew2;
pub const polyShapeGetCount = c.cpPolyShapeGetCount;
pub const polyShapeGetVert = c.cpPolyShapeGetVert;
pub const polyShapeGetRadius = c.cpPolyShapeGetRadius;
pub const constraintDestroy = c.cpConstraintDestroy;
pub const constraintFree = c.cpConstraintFree;
pub const constraintGetSpace = c.cpConstraintGetSpace;
pub const constraintGetBodyA = c.cpConstraintGetBodyA;
pub const constraintGetBodyB = c.cpConstraintGetBodyB;
pub const constraintGetMaxForce = c.cpConstraintGetMaxForce;
pub const constraintSetMaxForce = c.cpConstraintSetMaxForce;
pub const constraintGetErrorBias = c.cpConstraintGetErrorBias;
pub const constraintSetErrorBias = c.cpConstraintSetErrorBias;
pub const constraintGetMaxBias = c.cpConstraintGetMaxBias;
pub const constraintSetMaxBias = c.cpConstraintSetMaxBias;
pub const constraintGetCollideBodies = c.cpConstraintGetCollideBodies;
pub const constraintSetCollideBodies = c.cpConstraintSetCollideBodies;
pub const constraintGetPreSolveFunc = c.cpConstraintGetPreSolveFunc;
pub const constraintSetPreSolveFunc = c.cpConstraintSetPreSolveFunc;
pub const constraintGetPostSolveFunc = c.cpConstraintGetPostSolveFunc;
pub const constraintSetPostSolveFunc = c.cpConstraintSetPostSolveFunc;
pub const constraintGetUserData = c.cpConstraintGetUserData;
pub const constraintSetUserData = c.cpConstraintSetUserData;
pub const constraintGetImpulse = c.cpConstraintGetImpulse;
pub const constraintIsPinJoint = c.cpConstraintIsPinJoint;
pub const pinJointAlloc = c.cpPinJointAlloc;
pub const pinJointInit = c.cpPinJointInit;
pub const pinJointNew = c.cpPinJointNew;
pub const pinJointGetAnchorA = c.cpPinJointGetAnchorA;
pub const pinJointSetAnchorA = c.cpPinJointSetAnchorA;
pub const pinJointGetAnchorB = c.cpPinJointGetAnchorB;
pub const pinJointSetAnchorB = c.cpPinJointSetAnchorB;
pub const pinJointGetDist = c.cpPinJointGetDist;
pub const pinJointSetDist = c.cpPinJointSetDist;
pub const constraintIsSlideJoint = c.cpConstraintIsSlideJoint;
pub const slideJointAlloc = c.cpSlideJointAlloc;
pub const slideJointInit = c.cpSlideJointInit;
pub const slideJointNew = c.cpSlideJointNew;
pub const slideJointGetAnchorA = c.cpSlideJointGetAnchorA;
pub const slideJointSetAnchorA = c.cpSlideJointSetAnchorA;
pub const slideJointGetAnchorB = c.cpSlideJointGetAnchorB;
pub const slideJointSetAnchorB = c.cpSlideJointSetAnchorB;
pub const slideJointGetMin = c.cpSlideJointGetMin;
pub const slideJointSetMin = c.cpSlideJointSetMin;
pub const slideJointGetMax = c.cpSlideJointGetMax;
pub const slideJointSetMax = c.cpSlideJointSetMax;
pub const constraintIsPivotJoint = c.cpConstraintIsPivotJoint;
pub const pivotJointAlloc = c.cpPivotJointAlloc;
pub const pivotJointInit = c.cpPivotJointInit;
pub const pivotJointNew = c.cpPivotJointNew;
pub const pivotJointNew2 = c.cpPivotJointNew2;
pub const pivotJointGetAnchorA = c.cpPivotJointGetAnchorA;
pub const pivotJointSetAnchorA = c.cpPivotJointSetAnchorA;
pub const pivotJointGetAnchorB = c.cpPivotJointGetAnchorB;
pub const pivotJointSetAnchorB = c.cpPivotJointSetAnchorB;
pub const constraintIsGrooveJoint = c.cpConstraintIsGrooveJoint;
pub const grooveJointAlloc = c.cpGrooveJointAlloc;
pub const grooveJointInit = c.cpGrooveJointInit;
pub const grooveJointNew = c.cpGrooveJointNew;
pub const grooveJointGetGrooveA = c.cpGrooveJointGetGrooveA;
pub const grooveJointSetGrooveA = c.cpGrooveJointSetGrooveA;
pub const grooveJointGetGrooveB = c.cpGrooveJointGetGrooveB;
pub const grooveJointSetGrooveB = c.cpGrooveJointSetGrooveB;
pub const grooveJointGetAnchorB = c.cpGrooveJointGetAnchorB;
pub const grooveJointSetAnchorB = c.cpGrooveJointSetAnchorB;
pub const constraintIsDampedSpring = c.cpConstraintIsDampedSpring;
pub const dampedSpringAlloc = c.cpDampedSpringAlloc;
pub const dampedSpringInit = c.cpDampedSpringInit;
pub const dampedSpringNew = c.cpDampedSpringNew;
pub const dampedSpringGetAnchorA = c.cpDampedSpringGetAnchorA;
pub const dampedSpringSetAnchorA = c.cpDampedSpringSetAnchorA;
pub const dampedSpringGetAnchorB = c.cpDampedSpringGetAnchorB;
pub const dampedSpringSetAnchorB = c.cpDampedSpringSetAnchorB;
pub const dampedSpringGetRestLength = c.cpDampedSpringGetRestLength;
pub const dampedSpringSetRestLength = c.cpDampedSpringSetRestLength;
pub const dampedSpringGetStiffness = c.cpDampedSpringGetStiffness;
pub const dampedSpringSetStiffness = c.cpDampedSpringSetStiffness;
pub const dampedSpringGetDamping = c.cpDampedSpringGetDamping;
pub const dampedSpringSetDamping = c.cpDampedSpringSetDamping;
pub const dampedSpringGetSpringForceFunc = c.cpDampedSpringGetSpringForceFunc;
pub const dampedSpringSetSpringForceFunc = c.cpDampedSpringSetSpringForceFunc;
pub const constraintIsDampedRotarySpring = c.cpConstraintIsDampedRotarySpring;
pub const dampedRotarySpringAlloc = c.cpDampedRotarySpringAlloc;
pub const dampedRotarySpringInit = c.cpDampedRotarySpringInit;
pub const dampedRotarySpringNew = c.cpDampedRotarySpringNew;
pub const dampedRotarySpringGetRestAngle = c.cpDampedRotarySpringGetRestAngle;
pub const dampedRotarySpringSetRestAngle = c.cpDampedRotarySpringSetRestAngle;
pub const dampedRotarySpringGetStiffness = c.cpDampedRotarySpringGetStiffness;
pub const dampedRotarySpringSetStiffness = c.cpDampedRotarySpringSetStiffness;
pub const dampedRotarySpringGetDamping = c.cpDampedRotarySpringGetDamping;
pub const dampedRotarySpringSetDamping = c.cpDampedRotarySpringSetDamping;
pub const dampedRotarySpringGetSpringTorqueFunc = c.cpDampedRotarySpringGetSpringTorqueFunc;
pub const dampedRotarySpringSetSpringTorqueFunc = c.cpDampedRotarySpringSetSpringTorqueFunc;
pub const constraintIsRotaryLimitJoint = c.cpConstraintIsRotaryLimitJoint;
pub const rotaryLimitJointAlloc = c.cpRotaryLimitJointAlloc;
pub const rotaryLimitJointInit = c.cpRotaryLimitJointInit;
pub const rotaryLimitJointNew = c.cpRotaryLimitJointNew;
pub const rotaryLimitJointGetMin = c.cpRotaryLimitJointGetMin;
pub const rotaryLimitJointSetMin = c.cpRotaryLimitJointSetMin;
pub const rotaryLimitJointGetMax = c.cpRotaryLimitJointGetMax;
pub const rotaryLimitJointSetMax = c.cpRotaryLimitJointSetMax;
pub const constraintIsRatchetJoint = c.cpConstraintIsRatchetJoint;
pub const ratchetJointAlloc = c.cpRatchetJointAlloc;
pub const ratchetJointInit = c.cpRatchetJointInit;
pub const ratchetJointNew = c.cpRatchetJointNew;
pub const ratchetJointGetAngle = c.cpRatchetJointGetAngle;
pub const ratchetJointSetAngle = c.cpRatchetJointSetAngle;
pub const ratchetJointGetPhase = c.cpRatchetJointGetPhase;
pub const ratchetJointSetPhase = c.cpRatchetJointSetPhase;
pub const ratchetJointGetRatchet = c.cpRatchetJointGetRatchet;
pub const ratchetJointSetRatchet = c.cpRatchetJointSetRatchet;
pub const constraintIsGearJoint = c.cpConstraintIsGearJoint;
pub const gearJointAlloc = c.cpGearJointAlloc;
pub const gearJointInit = c.cpGearJointInit;
pub const gearJointNew = c.cpGearJointNew;
pub const gearJointGetPhase = c.cpGearJointGetPhase;
pub const gearJointSetPhase = c.cpGearJointSetPhase;
pub const gearJointGetRatio = c.cpGearJointGetRatio;
pub const gearJointSetRatio = c.cpGearJointSetRatio;
pub const constraintIsSimpleMotor = c.cpConstraintIsSimpleMotor;
pub const simpleMotorAlloc = c.cpSimpleMotorAlloc;
pub const simpleMotorInit = c.cpSimpleMotorInit;
pub const simpleMotorNew = c.cpSimpleMotorNew;
pub const simpleMotorGetRate = c.cpSimpleMotorGetRate;
pub const simpleMotorSetRate = c.cpSimpleMotorSetRate;
pub const spaceAlloc = c.cpSpaceAlloc;
pub const spaceInit = c.cpSpaceInit;
pub const spaceNew = c.cpSpaceNew;
pub const spaceDestroy = c.cpSpaceDestroy;
pub const spaceFree = c.cpSpaceFree;
pub const spaceGetIterations = c.cpSpaceGetIterations;
pub const spaceSetIterations = c.cpSpaceSetIterations;
pub const spaceGetGravity = c.cpSpaceGetGravity;
pub const spaceSetGravity = c.cpSpaceSetGravity;
pub const spaceGetDamping = c.cpSpaceGetDamping;
pub const spaceSetDamping = c.cpSpaceSetDamping;
pub const spaceGetIdleSpeedThreshold = c.cpSpaceGetIdleSpeedThreshold;
pub const spaceSetIdleSpeedThreshold = c.cpSpaceSetIdleSpeedThreshold;
pub const spaceGetSleepTimeThreshold = c.cpSpaceGetSleepTimeThreshold;
pub const spaceSetSleepTimeThreshold = c.cpSpaceSetSleepTimeThreshold;
pub const spaceGetCollisionSlop = c.cpSpaceGetCollisionSlop;
pub const spaceSetCollisionSlop = c.cpSpaceSetCollisionSlop;
pub const spaceGetCollisionBias = c.cpSpaceGetCollisionBias;
pub const spaceSetCollisionBias = c.cpSpaceSetCollisionBias;
pub const spaceGetCollisionPersistence = c.cpSpaceGetCollisionPersistence;
pub const spaceSetCollisionPersistence = c.cpSpaceSetCollisionPersistence;
pub const spaceGetUserData = c.cpSpaceGetUserData;
pub const spaceSetUserData = c.cpSpaceSetUserData;
pub const spaceGetStaticBody = c.cpSpaceGetStaticBody;
pub const spaceGetCurrentTimeStep = c.cpSpaceGetCurrentTimeStep;
pub const spaceIsLocked = c.cpSpaceIsLocked;
pub const spaceAddDefaultCollisionHandler = c.cpSpaceAddDefaultCollisionHandler;
pub const spaceAddCollisionHandler = c.cpSpaceAddCollisionHandler;
pub const spaceAddWildcardHandler = c.cpSpaceAddWildcardHandler;
pub const spaceAddShape = c.cpSpaceAddShape;
pub const spaceAddBody = c.cpSpaceAddBody;
pub const spaceAddConstraint = c.cpSpaceAddConstraint;
pub const spaceRemoveShape = c.cpSpaceRemoveShape;
pub const spaceRemoveBody = c.cpSpaceRemoveBody;
pub const spaceRemoveConstraint = c.cpSpaceRemoveConstraint;
pub const spaceContainsShape = c.cpSpaceContainsShape;
pub const spaceContainsBody = c.cpSpaceContainsBody;
pub const spaceContainsConstraint = c.cpSpaceContainsConstraint;
pub const spaceAddPostStepCallback = c.cpSpaceAddPostStepCallback;
pub const spacePointQuery = c.cpSpacePointQuery;
pub const spacePointQueryNearest = c.cpSpacePointQueryNearest;
pub const spaceSegmentQuery = c.cpSpaceSegmentQuery;
pub const spaceSegmentQueryFirst = c.cpSpaceSegmentQueryFirst;
pub const spaceBBQuery = c.cpSpaceBBQuery;
pub const spaceShapeQuery = c.cpSpaceShapeQuery;
pub const spaceEachBody = c.cpSpaceEachBody;
pub const spaceEachShape = c.cpSpaceEachShape;
pub const spaceEachConstraint = c.cpSpaceEachConstraint;
pub const spaceReindexStatic = c.cpSpaceReindexStatic;
pub const spaceReindexShape = c.cpSpaceReindexShape;
pub const spaceReindexShapesForBody = c.cpSpaceReindexShapesForBody;
pub const spaceUseSpatialHash = c.cpSpaceUseSpatialHash;
pub const spaceStep = c.cpSpaceStep;
pub const spaceDebugDraw = c.cpSpaceDebugDraw;
pub const momentForCircle = c.cpMomentForCircle;
pub const areaForCircle = c.cpAreaForCircle;
pub const momentForSegment = c.cpMomentForSegment;
pub const areaForSegment = c.cpAreaForSegment;
pub const momentForPoly = c.cpMomentForPoly;
pub const areaForPoly = c.cpAreaForPoly;
pub const centroidForPoly = c.cpCentroidForPoly;
pub const momentForBox = c.cpMomentForBox;
pub const momentForBox2 = c.cpMomentForBox2;
pub const convexHull = c.cpConvexHull;
pub const closetPointOnSegment = c.cpClosetPointOnSegment;
pub const circleShapeSetRadius = c.cpCircleShapeSetRadius;
pub const circleShapeSetOffset = c.cpCircleShapeSetOffset;
pub const segmentShapeSetEndpoints = c.cpSegmentShapeSetEndpoints;
pub const segmentShapeSetRadius = c.cpSegmentShapeSetRadius;
pub const polyShapeSetVerts = c.cpPolyShapeSetVerts;
pub const polyShapeSetVertsRaw = c.cpPolyShapeSetVertsRaw;
pub const polyShapeSetRadius = c.cpPolyShapeSetRadius;