// Copyright Epic Games, Inc. All Rights Reserved.

#pragma once

#include "CoreMinimal.h"
#include "Modules/ModuleManager.h"

class FMuJoCoUEModule : public IModuleInterface
{

	void *DLLHandle;

public:
	/** IModuleInterface 实现 */
	virtual void StartupModule() override;
	virtual void ShutdownModule() override;
};
