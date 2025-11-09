import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { CampaignsService } from './campaigns.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('campaigns')
@Controller('campaigns')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class CampaignsController {
  constructor(private campaignsService: CampaignsService) {}

  @Post()
  create(@Body() createDto: any) {
    return this.campaignsService.create(createDto);
  }

  @Get()
  findAll(@Query('companyId') companyId: string) {
    return this.campaignsService.findAll(companyId);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.campaignsService.findOne(id);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() updateDto: any) {
    return this.campaignsService.update(id, updateDto);
  }

  @Put(':id/pause')
  pause(@Param('id') id: string) {
    return this.campaignsService.pause(id);
  }

  @Put(':id/resume')
  resume(@Param('id') id: string) {
    return this.campaignsService.resume(id);
  }

  @Delete(':id')
  delete(@Param('id') id: string) {
    return this.campaignsService.delete(id);
  }
}
