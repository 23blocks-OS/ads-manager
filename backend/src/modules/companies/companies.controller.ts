import { Controller, Get, Post, Put, Body, Param, UseGuards, Request } from '@nestjs/common';
import { ApiTags, ApiBearerAuth } from '@nestjs/swagger';
import { CompaniesService } from './companies.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@ApiTags('companies')
@Controller('companies')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class CompaniesController {
  constructor(private companiesService: CompaniesService) {}

  @Post()
  create(@Request() req, @Body() createDto: any) {
    return this.companiesService.create(req.user.userId, createDto);
  }

  @Get()
  findAll(@Request() req) {
    return this.companiesService.findAll(req.user.userId);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.companiesService.findOne(id);
  }

  @Put(':id')
  update(@Param('id') id: string, @Body() updateDto: any) {
    return this.companiesService.update(id, updateDto);
  }

  @Put(':id/brand-guidelines')
  updateBrandGuidelines(@Param('id') id: string, @Body() guidelines: any) {
    return this.companiesService.updateBrandGuidelines(id, guidelines);
  }

  @Put(':id/budget-settings')
  updateBudgetSettings(@Param('id') id: string, @Body() settings: any) {
    return this.companiesService.updateBudgetSettings(id, settings);
  }
}
